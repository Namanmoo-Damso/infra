독거노인을 위한 AI 화상통화 및 관제 시스템의 인프라 구축 계획을 한 페이지로 요약한 **종합 안내서**입니다. 이 문서는 신규 엔지니어나 협업자가 전체 구조와 배포 메커니즘을 즉시 이해할 수 있도록 설계되었습니다.

---

# 📋 프로젝트: 독거노인 AI 케어 시스템 인프라 구축 가이드

## 1. 서비스 개요

* **대상:** 독거노인(모바일 앱) 및 지자체 사회복지사(웹 관제)
* **핵심 기능:** 실시간 AI 화상통화(정서 케어 및 건강 이상 징후 파악)
* **기술 스택:** Livekit(미디어), Next.js(웹), Python(API), GPU EC2(AI Agent), PostgreSQL/Redis

---

## 2. 인프라 아키텍처 (AWS 기반)

전체 인프라는 보안을 위해 **Private Subnet** 중심의 폐쇄적 구조를 가지며, 가용 영역(Multi-AZ) 확장이 용이하도록 설계되었습니다.

### **네트워크 구성**

* **Public Subnet:** 외부 진입점(ALB, NLB) 및 외부 통신용 NAT Gateway 배치.
* **Staging/Prod Private Subnet:** 서비스 환경별(Next.js, API, AI-Agent) 엄격한 격리.
* **Shared Private Subnet:** 전역에서 사용하는 **Livekit 클러스터** 및 전용 Redis 배치.
* **Data Private Subnet:** 환경별 독립된 RDS(PostgreSQL) 및 ElastiCache(Redis) 배치.

---

## 3. 핵심 설계 전략

### **① AI Agent 서버 최적화**

* **인스턴스:** GPU 최적화 모델(`g5.2xlarge`) 사용.
* **모델 배포:** 배포 안정성을 위해 **모델 가중치(Weights)를 Docker 이미지 내부에 포함**하여 GHCR(GitHub Container Registry)에서 배포. 외부 의존성 최소화.
* **운영:** 초기 단계에서는 오토스케일링 없이 충분한 자원을 선제적으로 할당하여 안정성 확보.

### **② 환경 분리 및 트래픽 제어**

* **도메인 기반 분기:** 단일 ALB에서 호스트 헤더(`api.com` vs `stg-api.com`)를 통해 각 환경으로 트래픽 분산.
* **미디어 트래픽:** 실시간 통화(UDP)는 NLB를 통해 Livekit 서버로 직접 연결.

### **③ 보안 및 관리 (SSM 기반)**

* **Zero SSH Port:** 모든 EC2는 Private Subnet에 위치하며 22번 포트를 개방하지 않음.
* **AWS SSM(Systems Manager):** 관리자는 IAM 권한과 SSM 터널링을 통해 보안 사고 없이 원격 서버에 접근 및 제어.

---

## 4. 배포 및 운영 프로세스

본 프로젝트는 **IaC(Terraform)**와 **Docker Context**를 결합하여 로컬에서 원격 환경을 효율적으로 제어합니다.

1. **인프라 프로비저닝 (Terraform):** VPC, IAM, EC2, DB 등 기본 자원을 코드로 생성.
2. **이미지 빌드 및 푸시:** GitHub Actions 등을 통해 모델이 포함된 이미지를 GHCR에 업로드.
3. **원격 연결 설정:** 로컬 PC에서 SSM 터널을 통해 각 EC2를 `docker context`로 등록.
4. **서비스 배포 (Docker Compose):** * 로컬에서 환경별 `.env` 파일을 로드.
* `docker --context [target] compose up -d` 명령으로 원격 서버에서 이미지 pull 및 컨테이너 실행.



---

## 5. 향후 확장 계획

* **Multi-AZ 도입:** 현재 싱글 AZ 구성을 성공적으로 배포한 후, 가용 영역을 추가하여 고가용성(HA) 확보.
* **Monitoring:** CloudWatch를 통해 AI 모델의 GPU 점유율 및 Livekit 세션 상태 실시간 관제.

---

## 6. v3 구현 계획

### **디렉토리 구조**

```
v3/
├── deployment-artifacts/
│   ├── ai-agent/
│   │   └── docker-compose.yml        # stt, ollama, agent, transcript-storage, kma-mcp (5개 이미지)
│   ├── api-server/
│   │   └── docker-compose.yml        # api, indexing-worker
│   ├── web-server/
│   │   └── docker-compose.yml        # web
│   ├── env.zip                       # 환경변수 백업 (S3 동기화용)
│   └── scripts/
│       ├── setup-docker-context.sh   # SSM 터널 + docker context 등록
│       └── deploy.sh                 # 배포 자동화 스크립트
│
├── terraform/                        # Terraform IaC
│   ├── main.tf                       # 메인 진입점
│   ├── vpc.tf                        # VPC, Subnet, NAT Gateway
│   ├── rds.tf                        # RDS PostgreSQL (Managed)
│   ├── elasticache.tf                # ElastiCache Redis (Managed)
│   ├── ec2.tf                        # AI-Agent (GPU), API, Web EC2
│   ├── alb.tf                        # Application Load Balancer
│   ├── nlb.tf                        # Network Load Balancer (Livekit 전용)
│   ├── security-groups.tf            # 보안그룹 규칙
│   ├── iam.tf                        # IAM Role, Instance Profile
│   ├── variables.tf                  # 입력 변수
│   ├── outputs.tf                    # 출력값
│   ├── backend.tf                    # S3 백엔드
│   └── provider.tf                   # AWS Provider
│
├── user-data/
│   ├── ai-agent-init.sh              # GPU 드라이버, Docker, SSM Agent 설치
│   ├── api-server-init.sh            # Docker, SSM Agent 설치
│   └── web-server-init.sh            # Docker, SSM Agent 설치
│
└── onboarding.md                     # 본 문서
```

### **주요 변경사항 (vs v2)**

#### ① AI Agent 멀티 이미지 전략
v2에서는 단일 `agent:v2` 이미지로 운영했지만, v3에서는 **5개 독립 이미지**로 분리:

| 서비스 | 이미지 | 업데이트 빈도 | GPU 필요 |
|--------|--------|--------------|----------|
| stt | `ghcr.io/.../stt:v3` | 낮음 (Whisper 모델) | O |
| ollama | `ghcr.io/.../ollama:v3` | 낮음 (LLM 모델) | O |
| agent | `ghcr.io/.../agent:v3` | **높음 (프롬프트 변경)** | X |
| transcript-storage | `ghcr.io/.../transcript-storage:v3` | 중간 | X |
| kma-mcp | `ghcr.io/.../kma-mcp:v3` | 낮음 | X |

**이유**: 프롬프트 엔지니어링이 포함된 `agent` 이미지는 빈번한 배포가 예상되므로,
GPU 의존적인 STT/LLM 이미지와 분리하여 배포 효율성 확보.

#### ② Managed 서비스 전환
- **RDS PostgreSQL**: EC2 DB → RDS (자동 백업, 패치, 고가용성)
- **ElastiCache Redis**: Docker Redis → ElastiCache (자동 페일오버, 스케일링)

#### ③ Livekit 서버 재활용
현재 `environments/dev/livekit`에서 운영 중인 서버를 production에서도 공용으로 사용.
추후 트래픽 증가 시 독립 클러스터로 분리 가능.

### **구현 단계**

1. **Terraform 인프라 프로비저닝**
   - VPC, Subnet, Security Groups
   - RDS, ElastiCache 생성
   - EC2 인스턴스 (AI-Agent, API, Web)
   - ALB/NLB 설정

2. **Docker Compose 파일 작성**
   - AI Agent용 (5개 서비스)
   - API Server용
   - Web Server용

3. **배포 스크립트 작성**
   - SSM 터널링 설정
   - Docker Context 등록
   - 원격 배포 자동화

4. **초기화 스크립트 (User Data)**
   - GPU 드라이버 설치
   - Docker 설치 및 설정
   - SSM Agent 활성화

