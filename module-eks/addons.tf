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
# Kubernetes Providers
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

################################################
# IMPORTANT: Prevent Terraform from reinstalling - ingress
################################################

resource "helm_release" "nginx_ingress" {
  name      = "ingress-nginx"
  namespace = "ingress-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  create_namespace = true
  force_update     = true
  replace          = true
  timeout          = 600

  values = [
    <<-YAML
    controller:
      admissionWebhooks:
        enabled: false
      service:
        type: LoadBalancer  # Changed from NodePort to LoadBalancer
        annotations:
          service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
      replicaCount: 1
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
    YAML
  ]
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

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.14.5"
  namespace  = "cert-manager"
  create_namespace = true

  # Use equals sign and brackets (older syntax)
  set = [{
    name  = "installCRDs"
    value = "true"
  }]

  depends_on = [helm_release.nginx_ingress]
}
#==================================================

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.51.6"
  namespace        = "argocd"
  create_namespace = true
  values           = [file("${path.module}/argocd-values.yaml")]

  # REMOVE cert_manager dependency if it's causing issues
  # depends_on = [helm_release.nginx_ingress]
  # depends_on       = [helm_release.nginx_ingress, helm_release.cert_manager]
}