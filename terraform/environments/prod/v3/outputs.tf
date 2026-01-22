# =============================================================================
# v3 배포 환경 출력값
# =============================================================================

# -----------------------------------------------------------------------------
# VPC 정보
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

# -----------------------------------------------------------------------------
# EC2 인스턴스 정보
# -----------------------------------------------------------------------------
output "ai_agent_instance_id" {
  description = "AI Agent EC2 인스턴스 ID"
  value       = aws_instance.ai_agent.id
}

output "ai_agent_private_ip" {
  description = "AI Agent 서버 Private IP"
  value       = aws_instance.ai_agent.private_ip
}

output "api_instance_id" {
  description = "API Server EC2 인스턴스 ID"
  value       = aws_instance.api_server.id
}

output "api_private_ip" {
  description = "API 서버 Private IP"
  value       = aws_instance.api_server.private_ip
}

output "web_instance_id" {
  description = "Web Server EC2 인스턴스 ID"
  value       = aws_instance.web_server.id
}

output "web_private_ip" {
  description = "Web 서버 Private IP"
  value       = aws_instance.web_server.private_ip
}

# -----------------------------------------------------------------------------
# RDS 정보
# -----------------------------------------------------------------------------
output "rds_endpoint" {
  description = "RDS PostgreSQL 엔드포인트"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_address" {
  description = "RDS PostgreSQL 주소"
  value       = aws_db_instance.postgres.address
}

# -----------------------------------------------------------------------------
# ElastiCache 정보
# -----------------------------------------------------------------------------
output "redis_endpoint" {
  description = "ElastiCache Redis 엔드포인트"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "redis_port" {
  description = "ElastiCache Redis 포트"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].port
}

# -----------------------------------------------------------------------------
# Load Balancer 정보
# -----------------------------------------------------------------------------
output "alb_dns_name" {
  description = "ALB DNS 이름"
  value       = aws_lb.main.dns_name
}

output "nlb_dns_name" {
  description = "NLB DNS 이름 (Livekit용)"
  value       = aws_lb.livekit.dns_name
}
