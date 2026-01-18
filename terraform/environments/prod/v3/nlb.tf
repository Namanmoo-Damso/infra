# =============================================================================
# Network Load Balancer (Livekit)
# =============================================================================
#
# 참고: 현재는 environments/dev/livekit의 기존 서버를 사용
# 이 파일은 향후 프로덕션 전용 Livekit 서버 구축 시 사용
# =============================================================================

# -----------------------------------------------------------------------------
# NLB
# -----------------------------------------------------------------------------
resource "aws_lb" "livekit" {
  name               = "${var.project_name}-${var.environment}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_c.id]

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-nlb"
    Environment = var.environment
    Purpose     = "Livekit"
  }
}

# -----------------------------------------------------------------------------
# Target Group (Livekit Server)
# -----------------------------------------------------------------------------
resource "aws_lb_target_group" "livekit" {
  name     = "${var.project_name}-${var.environment}-livekit-tg"
  port     = 7880
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    port                = 7880
    protocol            = "TCP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
  }

  deregistration_delay = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-livekit-tg"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Listener
# -----------------------------------------------------------------------------
resource "aws_lb_listener" "livekit_tcp" {
  load_balancer_arn = aws_lb.livekit.arn
  port              = 7880
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.livekit.arn
  }
}

# UDP Listener for WebRTC
resource "aws_lb_listener" "livekit_udp" {
  load_balancer_arn = aws_lb.livekit.arn
  port              = 50000
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.livekit_udp.arn
  }
}

resource "aws_lb_target_group" "livekit_udp" {
  name     = "${var.project_name}-${var.environment}-livekit-udp-tg"
  port     = 50000
  protocol = "UDP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    port                = 7880
    protocol            = "TCP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-livekit-udp-tg"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Target Group Attachments
# -----------------------------------------------------------------------------
# 참고: 현재는 dev의 기존 Livekit 서버를 사용하므로 attachment는 주석 처리
# 향후 프로덕션 전용 Livekit EC2 인스턴스 생성 시 활성화
#
# resource "aws_lb_target_group_attachment" "livekit" {
#   target_group_arn = aws_lb_target_group.livekit.arn
#   target_id        = aws_instance.livekit_server.id
#   port             = 7880
# }
