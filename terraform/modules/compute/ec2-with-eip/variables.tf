# =============================================================================
# EC2 인스턴스 with EIP 모듈 - 변수 정의
# =============================================================================

variable "instance_count" {
  description = "생성할 인스턴스 개수"
  type        = number
}

variable "ami_id" {
  description = "사용할 AMI ID"
  type        = string
}

variable "instance_type" {
  description = "인스턴스 타입 (예: t3.medium, g5.xlarge)"
  type        = string
}

variable "key_name" {
  description = "SSH 키 이름"
  type        = string
}

variable "security_group_id" {
  description = "보안 그룹 ID"
  type        = string
}

variable "tag_name" {
  description = "인스턴스 Name 태그"
  type        = string
}

variable "volume_size" {
  description = "루트 볼륨 크기 (GB)"
  type        = number
}

variable "user_data" {
  description = "인스턴스 초기화 스크립트 (선택사항)"
  type        = string
  default     = ""
}
