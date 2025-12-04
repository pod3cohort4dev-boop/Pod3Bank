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
# 🔥 FINAL FIX:
# Let Terraform KNOW the release exists,
# but DO NOT allow Terraform to install or update it.
############################################

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  namespace  = "ingress-nginx"

  # Dummy chart that does nothing
  chart      = "noop"
  repository = "https://charts.helm.sh/incubator"
  version    = "0.1.0"

  create_namespace = false

  lifecycle {
    ignore_changes = [
      chart,
      version,
      values,
      repository
    ]
  }

  values = [
    <<EOF
controller:
  allowSnippetAnnotations: true
EOF
  ]
}


############################################
# DISCOVER EXISTING NGINX LOAD BALANCER
############################################

data "aws_lb" "nginx_ingress" {
  depends_on = [helm_release.nginx_ingress]

  tags = {
    "kubernetes.io/service-name" = "ingress-nginx/ingress-nginx-controller"
  }
}


