############################################
# EKS DATA SOURCES
############################################

data "aws_lb" "nginx_ingress" {
  depends_on = [helm_release.nginx_ingress]

  tags = {
    "kubernetes.io/service-name" = "ingress-nginx/ingress-nginx-controller"
  }
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
  chart      = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  version    = "4.7.1"

  # Do NOT install because it already exists
  create_namespace = false
  timeout          = 1200

  # This prevents Terraform from updating or reinstalling it
  lifecycle {
    ignore_changes = [
      chart,
      version,
      values,
      repository,
    ]
  }

  # Dummy values so Terraform is satisfied
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

  # DO NOT depend on helm — this forces install!
  # depends_on = [helm_release.nginx_ingress]   ❌ REMOVE THIS LINE

  tags = {
    "kubernetes.io/service-name" = "ingress-nginx/ingress-nginx-controller"
  }
}
