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
