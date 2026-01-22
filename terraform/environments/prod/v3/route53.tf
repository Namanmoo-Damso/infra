# =============================================================================
# Route53 DNS Configuration
# =============================================================================

# -----------------------------------------------------------------------------
# Route53 Hosted Zone (기존 참조)
# -----------------------------------------------------------------------------
data "aws_route53_zone" "main" {
  name = "sodam.store"
}

# -----------------------------------------------------------------------------
# A Records (ALIAS) - ALB
# -----------------------------------------------------------------------------

# sodam.store → ALB (Web Server)
resource "aws_route53_record" "web" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "sodam.store"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# api.sodam.store → ALB (API Server)
resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "api.sodam.store"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# -----------------------------------------------------------------------------
# A Record (ALIAS) - NLB
# -----------------------------------------------------------------------------

# prod-livekit.sodam.store → NLB (LiveKit Server)
resource "aws_route53_record" "livekit" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "prod-livekit.sodam.store"
  type    = "A"

  alias {
    name                   = aws_lb.livekit.dns_name
    zone_id                = aws_lb.livekit.zone_id
    evaluate_target_health = true
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "web_domain" {
  description = "Web Server 도메인"
  value       = aws_route53_record.web.fqdn
}

output "api_domain" {
  description = "API Server 도메인"
  value       = aws_route53_record.api.fqdn
}

output "livekit_domain" {
  description = "Livekit Server 도메인"
  value       = aws_route53_record.livekit.fqdn
}
