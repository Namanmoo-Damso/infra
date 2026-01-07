# =============================================================================
# EC2 인스턴스 모듈 (EIP 없음)
# =============================================================================
# Public IP를 사용하는 EC2 인스턴스 생성 모듈
# 주의: 인스턴스 중지 후 재시작 시 Public IP가 변경될 수 있음
# =============================================================================

resource "aws_instance" "this" {
  count         = var.instance_count
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  # IAM 인스턴스 프로파일 (제공된 경우에만)
  iam_instance_profile = var.iam_instance_profile != "" ? var.iam_instance_profile : null

  # user_data가 제공된 경우에만 적용
  user_data = var.user_data != "" ? var.user_data : null

  # Public IP 자동 할당 활성화
  associate_public_ip_address = true

  tags = {
    Name = "${var.tag_name}-${count.index + 1}"
  }

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }
}
