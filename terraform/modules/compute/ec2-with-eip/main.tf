# =============================================================================
# EC2 인스턴스 with EIP 모듈
# =============================================================================
# EC2 인스턴스와 Elastic IP를 함께 생성하는 재사용 가능한 모듈
# =============================================================================

resource "aws_instance" "this" {
  count         = var.instance_count
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  # user_data가 제공된 경우에만 적용
  user_data = var.user_data != "" ? var.user_data : null

  tags = {
    Name = "${var.tag_name}-${count.index + 1}"
  }

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }
}

resource "aws_eip" "this" {
  count    = var.instance_count
  instance = aws_instance.this[count.index].id

  tags = {
    Name = "${var.tag_name}-eip-${count.index + 1}"
  }
}
