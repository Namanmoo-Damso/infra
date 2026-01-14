# =============================================================================
# 변수 정의
# =============================================================================

# LiveKit webhook URL (프로덕션 API 서버)
variable "api_webhook_urls" {
  description = "LiveKit webhook을 받을 API 서버 URL 목록"
  type        = list(string)
  default = [
    "https://sodam.store/webhook/livekit", # 프로덕션 API 서버
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
