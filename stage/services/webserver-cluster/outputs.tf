# output to show the DNS name of the ALB
output "alb_dns_name" {
  value       = aws_lb.terra-prod.dns_name
  description = "The domain name of the load balancer"
}
