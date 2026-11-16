output "ci_public_ip" {
  value = aws_instance.ci.public_ip
}

output "ci_private_ip" {
  value = aws_instance.ci.private_ip
}

output "k8s_public_ip" {
  value = aws_instance.k8s.public_ip
}

output "k8s_private_ip" {
  value = aws_instance.k8s.private_ip
}
