############################################
# EKS data sources (auth + endpoint)
############################################

data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.eks.name
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}

############################################
# Kubernetes Provider
############################################

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

############################################
# Helm Provider
############################################

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

############################################
# IMPORTANT: Prevent Terraform from reinstalling ingress
############################################

resource "helm_release" "nginx_ingress" {
  name      = "nginx-ingress"
  namespace = "ingress-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "nginx-ingress"
  version    = "4.12.0"

  lifecycle {
    ignore_changes = all
    prevent_destroy = true
  }

  timeout          = 1
  disable_webhooks = true
  recreate_pods    = false

}

############################################
# Discover NGINX Load Balancer
############################################

data "aws_lb" "nginx_ingress" {
  depends_on = [helm_release.nginx_ingress]

  # No depends_on on helm_release anymore – we’re just reading
  # depends_on = [helm_release.nginx_ingress]

#   tags = {
#     "kubernetes.io/service-name" = "ingress-nginx/ingress-nginx-controller"
#   }
# 
  tags = {
    "kubernetes.io/service-name" = "ingress-nginx/ingress-nginx-controller"
  }
}


 
