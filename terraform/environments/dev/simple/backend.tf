# 개발 환경 v1 - 로컬 state 관리
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
