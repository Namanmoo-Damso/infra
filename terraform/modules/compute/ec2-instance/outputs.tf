# =============================================================================
# EC2 인스턴스 모듈 (EIP 없음) - 출력값
# =============================================================================

output "instance_ids" {
  description = "생성된 인스턴스 ID 목록"
  value       = aws_instance.this[*].id
}

output "public_ips" {
  description = "인스턴스의 Public IP 목록"
  value       = aws_instance.this[*].public_ip
}

output "private_ips" {
  description = "인스턴스의 Private IP 목록"
  value       = aws_instance.this[*].private_ip
}
