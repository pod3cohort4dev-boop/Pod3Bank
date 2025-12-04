############################################
# EKS Cluster Data
############################################

data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

############################################
# nginx-ingress ALREADY INSTALLED
# Tell Terraform: DO NOT INSTALL, DO NOT MANAGE
############################################

resource "helm_release" "nginx_ingress" {
  name      = "nginx-ingress"
  namespace = "ingress-nginx"

  # Dummy values (Terraform needs chart info)
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.12.0"

  # ⭐ THIS IS THE MAGIC FIX ⭐
  lifecycle {
    ignore_changes = all   # Ignore all updates from Terraform
    prevent_destroy = true # Prevent Terraform from deleting it
  }
}

############################################
# Discover NGINX Ingress Load Balancer
############################################

data "aws_lb" "nginx_ingress" {
  depends_on = [helm_release.nginx_ingress]

  tags = {
    "kubernetes.io/service-name" = "ingress-nginx/ingress-nginx-controller"
  }
}
