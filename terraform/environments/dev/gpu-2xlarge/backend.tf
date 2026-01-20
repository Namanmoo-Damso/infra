# 테스트 환경 v2 - 로컬 state 관리
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
