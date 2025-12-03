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

  # Minimal chart info (Terraform requires these)
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  # Tell Terraform to IGNORE everything because ingress already exists
  lifecycle {
    ignore_changes = [
      chart,
      repository,
      version,
      values,
    ]
  }
}

############################################
# Discover NGINX Load Balancer
############################################

data "aws_lb" "nginx_ingress" {
  depends_on = [helm_release.nginx_ingress]

  tags = {
    "kubernetes.io/service-name" = "ingress-nginx/ingress-nginx-controller"
  }
}
