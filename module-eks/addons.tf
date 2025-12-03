############################################
# NGINX Ingress via Helm
############################################

# Leave these providers commented if you already define helm/kubernetes
# providers in the root module and pass them down.

# provider "helm" {
#   kubernetes = {
#     host                   = aws_eks_cluster.eks.endpoint
#     cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.eks.token
#   }
# }

# provider "kubernetes" {
#   host                   = aws_eks_cluster.eks.endpoint
#   cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.eks.token
# }

# data "aws_eks_cluster_auth" "eks" {
#   name = aws_eks_cluster.eks.name
# }

resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.12.0"
  namespace        = "ingress-nginx"
  create_namespace = true

  values = [file("${path.module}/nginx-ingress-values.yaml")]

  depends_on = [
    aws_eks_node_group.eks_node_group
  ]
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
