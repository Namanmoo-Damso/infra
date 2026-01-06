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
