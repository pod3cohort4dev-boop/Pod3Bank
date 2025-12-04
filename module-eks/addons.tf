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
# HELM PROVIDER (currently unused, but harmless)
############################################

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

############################################
# DISCOVER EXISTING NGINX LOAD BALANCER
# (ingress controller was installed manually)
############################################

data "aws_lb" "nginx_ingress" {
  # No depends_on on helm_release anymore – we’re just reading
  depends_on = [helm_release.nginx_ingress]

#   tags = {
#     "kubernetes.io/service-name" = "ingress-nginx/ingress-nginx-controller"
#   }
# }
  tags = {
    "kubernetes.io/service-name" = "ingress-nginx/ingress-nginx-controller"
  }
}


 
