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
# IMPORTANT: Prevent Terraform from reinstalling- ingress
################################################

resource "helm_release" "nginx_ingress" {
  name      = "ingress-nginx"
  namespace = "ingress-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.12.0"
  create_namespace = true

  force_update = true
  replace      = true
  
  # INCREASE TIMEOUT SIGNIFICANTLY
  timeout = 600  # 10 minutes, not 1 second!

  # DISABLE ADMISSION WEBHOOKS (causing the secret error)
  set {
    name  = "controller.admissionWebhooks.enabled"
    value = "false"
  }

  # Use NodePort instead of LoadBalancer to avoid IAM issues
  set {
    name  = "controller.service.type"
    value = "NodePort"
  }

  set {
    name  = "controller.replicaCount"
    value = "1"
  }

  # Minimal resource requests
  set {
    name  = "controller.resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "128Mi"
  }

  # Add security context
  set {
    name  = "controller.podSecurityContext.enabled"
    value = "true"
  }

  set {
    name  = "controller.containerSecurityContext.enabled"
    value = "true"
  }

  # Optional: Remove lifecycle block or simplify it
  # lifecycle {
  #   ignore_changes = [chart, repository]
  # }

  depends_on = [
    # Add any dependencies here, e.g.:
    # module.eks.cluster_id,
    # module.eks.cluster_endpoint
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