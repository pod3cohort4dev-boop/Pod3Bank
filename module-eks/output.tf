############################################
# EKS MODULE OUTPUTS
############################################

# EKS Cluster Name
output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.eks.name
}

# EKS API Endpoint
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.eks.endpoint
}

# EKS Cluster Certificate Authority
output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required for kubectl"
  value       = aws_eks_cluster.eks.certificate_authority[0].data
}


############################################
# INGRESS NGINX LOAD BALANCER
############################################

# Hostname of the AWS Load Balancer created by ingress-nginx
output "nginx_ingress_load_balancer_hostname" {
  description = "Load Balancer hostname created by ingress-nginx"
  value       = data.aws_lb.nginx_ingress.dns_name
}

# Optional: Same as above but shorter name
output "nginx_ingress_lb_dns" {
  description = "DNS hostname of ingress-nginx LB"
  value       = data.aws_lb.nginx_ingress.dns_name
}

# Optional: LB IP (may be empty because AWS LBs use DNS by default)
output "nginx_lb_ip" {
  description = "IP address of ingress-nginx LB (usually empty for AWS NLB/ALB)"
  value       = data.aws_lb.nginx_ingress.ip_address_type == "ipv4" ? data.aws_lb.nginx_ingress.dns_name : ""
}
