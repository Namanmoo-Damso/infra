# =============================================================================
# 테스트 환경 v1 - 출력값
# =============================================================================

# -----------------------------------------------------------------------------
# c7i 테스트 서버
# -----------------------------------------------------------------------------
output "c7i_test_instance_ids" {
  description = "c7i 테스트 서버 인스턴스 ID"
  value       = module.c7i_test.instance_ids
}

output "c7i_test_public_ips" {
  description = "c7i 테스트 서버 Public IP"
  value       = module.c7i_test.public_ips
}

output "c7i_test_private_ips" {
  description = "c7i 테스트 서버 Private IP"
  value       = module.c7i_test.private_ips
}

# -----------------------------------------------------------------------------
# Graviton4 테스트 서버
# -----------------------------------------------------------------------------
output "graviton4_test_instance_ids" {
  description = "Graviton4 테스트 서버 인스턴스 ID"
  value       = module.graviton4_test.instance_ids
}

output "graviton4_test_public_ips" {
  description = "Graviton4 테스트 서버 Public IP"
  value       = module.graviton4_test.public_ips
}

output "graviton4_test_private_ips" {
  description = "Graviton4 테스트 서버 Private IP"
  value       = module.graviton4_test.private_ips
}
