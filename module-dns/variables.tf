variable "environment" {
  type = string
}

variable "domain_name" {
  type = string
}

# Optional until NGINX ingress Load Balancer exists
variable "nginx_lb_ip" {
  type    = string
  default = null
}
