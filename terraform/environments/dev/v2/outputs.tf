# =============================================================================
# Outputs - LiveKit 서버 접속 정보
# =============================================================================

output "livekit_server_public_ip" {
  description = "LiveKit 서버 Public IP"
  value       = module.livekit_server.public_ips
}

output "livekit_server_instance_ids" {
  description = "LiveKit 서버 인스턴스 ID"
  value       = module.livekit_server.instance_ids
}

output "livekit_websocket_url" {
  description = "LiveKit WebSocket URL (API 서버 내부 통신용)"
  value       = "ws://livekit.sodam.store:7880"
}

output "livekit_public_url" {
  description = "LiveKit Public URL (클라이언트 WebRTC 연결용)"
  value       = "wss://livekit.sodam.store"
}
