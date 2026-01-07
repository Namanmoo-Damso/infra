# 전역 리소스 (보안 그룹 등)의 state를 로컬에서 관리
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
