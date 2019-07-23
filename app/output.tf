output "alb_cname" {
  value = aws_lb.main.dns_name
}
