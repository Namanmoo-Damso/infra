# =============================================================================
# 개발 환경 v1 - 출력값
# =============================================================================

output "general_dev_server_ids" {
  description = "범용 개발 서버 인스턴스 ID 목록"
  value       = module.general_dev_servers.instance_ids
}

output "general_dev_server_public_ips" {
  description = "범용 개발 서버 Public IP 목록"
  value       = module.general_dev_servers.public_ips
}

output "general_dev_server_private_ips" {
  description = "범용 개발 서버 Private IP 목록"
  value       = module.general_dev_servers.private_ips
}
