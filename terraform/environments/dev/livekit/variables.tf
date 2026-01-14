# =============================================================================
# 변수 정의
# =============================================================================

variable "api_webhook_urls" {
  description = "LiveKit webhook을 받을 API 서버 URL 목록"
  type        = list(string)
  default = [
    "https://sodam.store/webhook/livekit",   # 공유 개발 서버
    "https://1.sodam.store/webhook/livekit", # 개발자 1
    "https://2.sodam.store/webhook/livekit", # 개발자 2
    "https://3.sodam.store/webhook/livekit", # 개발자 3
    "https://4.sodam.store/webhook/livekit", # 개발자 4
    "https://5.sodam.store/webhook/livekit", # 개발자 5
  ]
}

variable "livekit_api_key" {
  description = "LiveKit API Key"
  type        = string
  default     = "LK_154f88960804a7ec"
  sensitive   = true
}

variable "livekit_api_secret" {
  description = "LiveKit API Secret"
  type        = string
  default     = "1d4b32dac495e14fced680129935a9eb8300e9a73841b08b0edae746a0c123b2"
  sensitive   = true
}
