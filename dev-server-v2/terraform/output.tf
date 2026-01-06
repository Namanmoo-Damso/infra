output "dev_server_ids" {
  value = module.dev-server.instance_ids
}

output "dev_server_public_ips" {
  value = module.dev-server.public_ips
}

output "cpu_test_ids" {
  value = module.cpu_test.instance_ids
}

output "cpu_test_public_ips" {
  value = module.cpu_test.public_ips
}

# Graviton4 벤치마크 서버 출력
output "graviton4_test_ids" {
  value = module.graviton4_test.instance_ids
}

output "graviton4_test_public_ips" {
  value = module.graviton4_test.public_ips
}

# ============================================================================
# AI GPU 서버 출력
# ============================================================================

# AI GPU 개발 서버
output "ai_gpu_dev_ids" {
  description = "AI GPU 개발 서버 인스턴스 ID 목록"
  value       = module.ai_gpu_dev.instance_ids
}

output "ai_gpu_dev_public_ips" {
  description = "AI GPU 개발 서버 Public IP (Elastic IP)"
  value       = module.ai_gpu_dev.public_ips
}

# AI GPU 배포 서버
output "ai_gpu_prod_ids" {
  description = "AI GPU 프로덕션 서버 인스턴스 ID 목록"
  value       = module.ai_gpu_prod.instance_ids
}

output "ai_gpu_prod_public_ips" {
  description = "AI GPU 프로덕션 서버 Public IP (Elastic IP)"
  value       = module.ai_gpu_prod.public_ips
}
