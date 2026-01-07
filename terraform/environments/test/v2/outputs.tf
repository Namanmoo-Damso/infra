# =============================================================================
# 테스트 환경 v2 - 출력값
# =============================================================================

output "ai_gpu_dev_instance_ids" {
  description = "AI GPU 개발 서버 인스턴스 ID 목록"
  value       = module.ai_gpu_dev_servers.instance_ids
}

output "ai_gpu_dev_public_ips" {
  description = "AI GPU 개발 서버 Public IP 목록"
  value       = module.ai_gpu_dev_servers.public_ips
}

output "ai_gpu_dev_private_ips" {
  description = "AI GPU 개발 서버 Private IP 목록"
  value       = module.ai_gpu_dev_servers.private_ips
}
