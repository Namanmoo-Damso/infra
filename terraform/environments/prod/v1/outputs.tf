# =============================================================================
# 배포 환경 v1 - 출력값
# =============================================================================

output "prod_server_instance_id" {
  description = "배포 서버 인스턴스 ID"
  value       = module.prod_server.instance_ids[0]
}

output "prod_server_public_ip" {
  description = "배포 서버 Public IP"
  value       = module.prod_server.public_ips[0]
}

output "prod_server_private_ip" {
  description = "배포 서버 Private IP"
  value       = module.prod_server.private_ips[0]
}
