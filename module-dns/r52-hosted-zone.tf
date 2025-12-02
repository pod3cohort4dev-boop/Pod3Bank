#########################################################
# Route53 Hosted Zone
#########################################################

resource "aws_route53_zone" "r53_zone" {
  name          = var.domain-name
  comment       = "Managed by Terraform"
  force_destroy = false

  tags = {
    Name        = "${var.environment}-hosted-zone"
    Environment = var.environment
  }
}

#########################################################
# CNAME Records – all point to Nginx Ingress LB hostname
#########################################################

# bank app frontend
resource "aws_route53_record" "bank" {
  zone_id = aws_route53_zone.r53_zone.zone_id
  name    = "bank.${var.domain-name}"        # bank.pentaops.online
  type    = "CNAME"
  ttl     = 300
  records = [module.eks-deployment.nginx_ingress_load_balancer_hostname]
}

# bank app backend/api
resource "aws_route53_record" "bankapi" {
  zone_id = aws_route53_zone.r53_zone.zone_id
  name    = "bankapi.${var.domain-name}"     # bankapi.pentaops.online
  type    = "CNAME"
  ttl     = 300
  records = [module.eks-deployment.nginx_ingress_load_balancer_hostname]
}

# ArgoCD
resource "aws_route53_record" "argocd" {
  zone_id = aws_route53_zone.r53_zone.zone_id
  name    = "argocd.${var.domain-name}"      # argocd.pentaops.online
  type    = "CNAME"
  ttl     = 300
  records = [module.eks-deployment.nginx_ingress_load_balancer_hostname]
}

