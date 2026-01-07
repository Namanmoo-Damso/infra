# =============================================================================
# EC2 인스턴스 with EIP 모듈 - 출력값
# =============================================================================

output "instance_ids" {
  description = "생성된 인스턴스 ID 목록"
  value       = aws_instance.this[*].id
}

output "public_ips" {
  description = "할당된 Elastic IP 목록"
  value       = aws_eip.this[*].public_ip
}
