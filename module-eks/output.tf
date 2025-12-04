############################################
# EKS MODULE OUTPUTS (FIXED)
############################################

# EKS Cluster Name
output "cluster_name" {
  value = aws_eks_cluster.eks.name
}

# EKS Cluster Endpoint
output "cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

# EKS Cluster Certificate Authority
output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.eks.certificate_authority[0].data
}

# NGINX Ingress LB Hostname
output "nginx_ingress_load_balancer_hostname" {
  value = data.aws_lb.nginx_ingress.dns_name
}

# NGINX Ingress LB DNS (optional)
output "nginx_ingress_lb_dns" {
  value = data.aws_lb.nginx_ingress.dns_name
}

# NGINX Ingress LB IP (optional)
output "nginx_lb_ip" {
  value = data.aws_lb.nginx_ingress.ip_address_type == "ipv4" ? data.aws_lb.nginx_ingress.dns_name : ""
}
