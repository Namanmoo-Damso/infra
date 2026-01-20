# =============================================================================
# Network Load Balancer (Livekit)
# =============================================================================
#
# NLB는 Signaling(WSS) 트래픽만 처리 (TCP 7880)
# WebRTC Media Stream(UDP 50000-60000)은 클라이언트가 LiveKit EC2 Public IP로 직접 연결
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

# -----------------------------------------------------------------------------
# Target Group Attachments
# -----------------------------------------------------------------------------
resource "aws_lb_target_group_attachment" "livekit_tcp" {
  target_group_arn = aws_lb_target_group.livekit.arn
  target_id        = aws_instance.livekit_server.id
  port             = 7880
}
