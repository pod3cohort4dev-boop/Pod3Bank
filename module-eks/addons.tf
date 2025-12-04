############################################
# EKS DATA SOURCES
############################################

data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.eks.name
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}

############################################
# KUBERNETES PROVIDER
############################################

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

############################################
# HELM PROVIDER
############################################

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

############################################
# FIXED: DO NOT RECREATE EXISTING INGRESS
############################################

resource "helm_release" "nginx_ingress" {
  name      = "nginx-ingress"
  namespace = "ingress-nginx"

  # Dummy chart info — Terraform MUST see these fields but will ignore them
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.12.0"

  ########################################
  # 🔥 THIS BLOCK FIXES THE ERROR
  ########################################
  lifecycle {
    ignore_changes = [
      name,
      namespace,
      repository,
      chart,
      version,
      values,
      set
    ]
    prevent_destroy = true
  }

  # Terraform MUST NOT attempt install/check anything
  timeout          = 1
  disable_webhooks = true
  recreate_pods    = false
}

############################################
# DISCOVER EXISTING NGINX LOAD BALANCER
############################################

data "aws_lb" "nginx_ingress" {
  depends_on = [helm_release.nginx_ingress]

#   tags = {
#     "kubernetes.io/service-name" = "ingress-nginx/ingress-nginx-controller"
#   }
# }
  tags = {
    "kubernetes.io/service-name" = "ingress-nginx/ingress-nginx-controller"
  }
}
 
