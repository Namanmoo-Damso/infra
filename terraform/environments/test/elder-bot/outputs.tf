# =============================================================================
# Outputs - Python Bot 서버 접속 정보
# =============================================================================

output "python_bot_server_public_ip" {
  description = "Python Bot 서버 Public IP"
  value       = module.python_bot_server.public_ips
}

output "python_bot_server_instance_ids" {
  description = "Python Bot 서버 인스턴스 ID"
  value       = module.python_bot_server.instance_ids
}
