# =============================================================================
# EC2 인스턴스 모듈 (EIP 없음) - 변수 정의
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
  description = "인스턴스 타입 (예: t3.medium, c7i.xlarge)"
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

variable "iam_instance_profile" {
  description = "IAM 인스턴스 프로파일 이름 (선택사항)"
  type        = string
  default     = ""
}

variable "start_stopped" {
  description = "인스턴스를 stopped 상태로 생성할지 여부"
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "인스턴스를 생성할 가용 영역 (선택사항)"
  type        = string
  default     = ""
}
