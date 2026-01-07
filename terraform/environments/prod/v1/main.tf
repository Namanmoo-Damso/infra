# =============================================================================
# 배포 환경 v1 - 단일 서버 docker-compose 배포
# =============================================================================

# -----------------------------------------------------------------------------
# Global 리소스 참조 (remote state)
# -----------------------------------------------------------------------------
data "terraform_remote_state" "global" {
  backend = "local"
  config = {
    path = "../../global/terraform.tfstate"
  }
}

# -----------------------------------------------------------------------------
# 보안 그룹 참조 (global에서 생성된 것)
# -----------------------------------------------------------------------------
data "aws_security_group" "general_dev_server" {
  name = "general-dev-server"
}

# -----------------------------------------------------------------------------
# 배포 서버 (docker-compose로 전체 스택 실행)
# -----------------------------------------------------------------------------
# EIP 대신 Public IP 사용 (EIP 쿼타 절약)
# 주의: 인스턴스 중지하지 말 것 (IP 변경됨 -> 수동으로 Route53 A레코드 수정필요)
# -----------------------------------------------------------------------------
module "prod_server" {
  source = "../../../modules/compute/ec2-instance"

  instance_count    = 1
  ami_id            = "ami-0c447e8442d5380a3" # Ubuntu 24.04 LTS
  instance_type     = "c7i.xlarge"            # 4 vCPU, 8GB RAM
  volume_size       = 50
  key_name          = "dev-server"
  security_group_id = data.aws_security_group.general_dev_server.id
  tag_name          = "prod-v1-server"

  # IAM 인스턴스 프로파일 (S3 접근용)
  iam_instance_profile = data.terraform_remote_state.global.outputs.prod_ec2_instance_profile_name

  # user_data 추후 추가 예정:
  # - Docker & Docker Compose 설치
  # - AWS CLI 설치
  # - S3에서 docker-compose.yml, env.zip 다운로드
  # - GitHub Container Registry에서 이미지 pull
  # - docker-compose up -d
  # user_data = file("${path.module}/user-data/init.sh")
}
