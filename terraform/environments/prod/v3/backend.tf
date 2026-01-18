# v3 배포 환경 - 로컬 state 관리
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
