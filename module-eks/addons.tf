############################################
# EKS auth for Kubernetes / Helm providers
############################################

data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.eks.name
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
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
# NGINX Ingress (Terraform will NOT reinstall
# after you import it)
############################################

resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  namespace        = "ingress-nginx"
  create_namespace = true

  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.12.0"

  values = [
    file("${path.module}/nginx-ingress-values.yaml")
  ]

  timeout = 600
  wait    = true
  atomic  = true
}

############################################
# GET NGINX Load Balancer (using annotation)
############################################
data "kubernetes_service" "nginx_svc" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [
    helm_release.nginx_ingress
  ]
}

output "nginx_ingress_load_balancer_hostname" {
  value = data.kubernetes_service.nginx_svc.status[0].load_balancer[0].ingress[0].hostname
}
