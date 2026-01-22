# =============================================================================
# Application Load Balancer (API, Web)
# =============================================================================

# -----------------------------------------------------------------------------
# ALB
# -----------------------------------------------------------------------------
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_c.id]

  enable_deletion_protection = false
  enable_http2               = true
  # SSE 통신을 위해 Idle Timeout을 60초(기본값)에서 3600초(1h)로 증가
  idle_timeout = 3600

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Target Groups
# -----------------------------------------------------------------------------

# API Target Group
resource "aws_lb_target_group" "api" {
  name     = "${var.project_name}-${var.environment}-api-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/healthz"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  # SSE 연결 배수(draining) 시간을 확보하기 위해 300초로 증가
  deregistration_delay = 300

  # SSE 재연결 시 동일 인스턴스 유지를 위해 Stickiness 활성화
  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 86400
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-api-tg"
    Environment = var.environment
  }
}

# Web Target Group
resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-${var.environment}-web-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200,307"
  }

  deregistration_delay = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-web-tg"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Target Group Attachments
# -----------------------------------------------------------------------------

resource "aws_lb_target_group_attachment" "api" {
  target_group_arn = aws_lb_target_group.api.arn
  target_id        = aws_instance.api_server.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web_server.id
  port             = 3000
}

# -----------------------------------------------------------------------------
# Listeners
# -----------------------------------------------------------------------------

# HTTP Listener (Redirect to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# -----------------------------------------------------------------------------
# Listener Rules (Host-based routing)
# -----------------------------------------------------------------------------

# API 도메인 라우팅
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    host_header {
      values = ["api.${var.domain_name}"]
    }
  }
}

# Web 도메인 라우팅 (default는 이미 설정됨)
