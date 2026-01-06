module "dev-server" {
  source = "./modules/ec2-instance-with-eip"

  ami_id            = "ami-0c447e8442d5380a3"
  instance_count    = 5
  instance_type     = "t3.medium"
  volume_size       = 20
  key_name          = "dev-server"
  security_group_id = data.aws_security_group.general_dev_server.id
  tag_name          = "general_dev_server"
}

module "cpu_test" {
  source = "./modules/ec2-instance-with-eip"

  ami_id            = "ami-0c447e8442d5380a3"
  instance_count    = 1
  instance_type     = "c7i.xlarge"
  volume_size       = 20
  key_name          = "dev-server"
  security_group_id = data.aws_security_group.general_dev_server.id
  tag_name          = "c7i-xlarge-benchmark-server"
}

# C8g.xlarge (AWS Graviton4) 벤치마크 서버
# - 목적: C7i(Intel) 대비 Graviton4(ARM) 성능 비교
# - 프로세서: AWS Graviton4 (ARM64, 최신 세대)
# - 예상 성능: C7g 대비 30% 향상, C7i 대비 우수한 가격 대비 성능
# - 주의: ARM 아키텍처이므로 소프트웨어 호환성 확인 필요
module "graviton4_test" {
  source = "./modules/ec2-instance-with-eip"

  ami_id            = "ami-04f06fb5ae9dcc778" # Ubuntu 24.04 ARM64 (for Graviton)
  instance_count    = 1
  instance_type     = "c8g.xlarge" # AWS Graviton4 (ARM64, 4 vCPU, 8GB RAM)
  volume_size       = 20
  key_name          = "dev-server"
  security_group_id = data.aws_security_group.general_dev_server.id
  tag_name          = "c8g-xlarge-graviton4-benchmark"
}

# ============================================================================
# AI GPU 서버 (LiveKit 실시간 음성/영상 에이전트)
# ============================================================================

# AI GPU 개발 서버
# - 용도: 모델 개발, 테스트, 실험
# - GPU: NVIDIA A10G (24GB VRAM)
# - 모델: Whisper (STT) + LLM 7B (대화) + TTS (음성 합성)
# - 예상 세션: 각 80-100명 동시 처리 가능
#
# 저장소 구성:
# - 로컬 EBS (200GB): 모델 파일(30GB) + 학습 데이터셋(100GB) + 앱/로그(70GB)
# - 외부 연동: RDS (사용자 DB), 벡터 DB (RAG 지식베이스), S3 (데이터셋 백업)
module "ai_gpu_dev" {
  source = "./modules/ec2-instance-with-eip"

  ami_id            = "ami-09399dbfdc84fada6" # Deep Learning Base GPU AMI (Ubuntu 24.04)
  instance_count    = 2
  instance_type     = "g5.xlarge" # NVIDIA A10G 24GB, 4 vCPU, 16GB RAM
  volume_size       = 200
  key_name          = "dev-server"
  security_group_id = aws_security_group.ai_gpu_server.id
  tag_name          = "ai-gpu-dev-server"
}

# AI GPU 배포 서버
# - 로드 밸런싱: ALB로 트래픽 분산
# - GPU: NVIDIA A10G (24GB VRAM)
# - 총 처리 용량: ~800명 동시 세션 (8대 × 100명)
# - Auto Scaling: 부하에 따라 자동 증감 가능
#
# 저장소 구성:
# - 로컬 EBS (150GB): 모델 파일(30GB) + 앱/로그(40GB) + 여유(80GB)
# - 외부 연동: RDS (사용자 DB, 대화 기록), 벡터 DB (RAG), S3 (로그 아카이브)
# - 실시간 데이터: 모두 데이터베이스 통신 (S3는 비실시간 로그만)
module "ai_gpu_prod" {
  source = "./modules/ec2-instance-with-eip"

  ami_id            = "ami-09399dbfdc84fada6" # Deep Learning Base GPU AMI (Ubuntu 24.04)
  instance_count    = 8
  instance_type     = "g5.xlarge" # NVIDIA A10G 24GB, 4 vCPU, 16GB RAM
  volume_size       = 150
  key_name          = "dev-server"
  security_group_id = aws_security_group.ai_gpu_server.id
  tag_name          = "ai-gpu-prod-server"
}
