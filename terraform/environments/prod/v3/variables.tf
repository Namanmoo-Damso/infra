# =============================================================================
# v3 배포 환경 변수 정의
# =============================================================================

# -----------------------------------------------------------------------------
# 환경 설정
# -----------------------------------------------------------------------------
variable "environment" {
  description = "배포 환경"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "sodam"
}

# -----------------------------------------------------------------------------
# 네트워크 설정
# -----------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone_a" {
  description = "첫 번째 가용 영역"
  type        = string
  default     = "ap-northeast-2a"
}

variable "availability_zone_c" {
  description = "두 번째 가용 영역"
  type        = string
  default     = "ap-northeast-2c"
}

# -----------------------------------------------------------------------------
# EC2 인스턴스 설정
# -----------------------------------------------------------------------------
variable "ai_agent_instance_type" {
  description = "AI Agent 서버 인스턴스 타입 (GPU 필요)"
  type        = string
  default     = "g5.2xlarge" # 1 GPU, 8 vCPU, 32GB RAM
}

variable "api_instance_type" {
  description = "API 서버 인스턴스 타입"
  type        = string
  default     = "t3.medium" # 2 vCPU, 4GB RAM
}

variable "web_instance_type" {
  description = "Web 서버 인스턴스 타입"
  type        = string
  default     = "t3.small" # 2 vCPU, 2GB RAM
}

variable "key_name" {
  description = "EC2 키페어 이름"
  type        = string
  default     = "dev-server"
}

# -----------------------------------------------------------------------------
# RDS 설정
# -----------------------------------------------------------------------------
variable "db_instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
  default     = "sodam_prod"
}

variable "db_username" {
  description = "데이터베이스 마스터 사용자명"
  type        = string
  default     = "sodam_admin"
  sensitive   = true
}

variable "db_password" {
  description = "데이터베이스 마스터 비밀번호"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# ElastiCache 설정
# -----------------------------------------------------------------------------
variable "redis_node_type" {
  description = "ElastiCache Redis 노드 타입"
  type        = string
  default     = "cache.t3.micro"
}

# -----------------------------------------------------------------------------
# 도메인 설정
# -----------------------------------------------------------------------------
variable "domain_name" {
  description = "기본 도메인"
  type        = string
  default     = "sodam.store"
}

variable "livekit_domain" {
  description = "Livekit 서버 도메인"
  type        = string
  default     = "livekit.sodam.store"
}

variable "acm_certificate_arn" {
  description = "ACM 인증서 ARN (HTTPS용)"
  type        = string
  sensitive   = true
}
