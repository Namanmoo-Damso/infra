## 개발하려는 제품 설명

- 개인-서버(AI 페르소나) 영상 통화 서비스
- 영상 통화 종합 관제
- AI 활용 영상/음성 분석 및 RAG 파이프라인의 데이터베이스로 활용

## 인프라 아키텍쳐

- 개발 비용(시간, 학습량) 최소화를 위한 설계
- 총 5개의 레포지토리
    - mobile: 모바일 클라이언트
    - FE: 관제 클라이언트
    - BE: livekit 서버 및 범용 api서버
    - AI: RAG 파이프라인
    - infra: 개발서버 및 배포서버 자동화 등


### 개발 서버

- FE/BE팀

    - 안정화 버전 AI 서버로 접속해서 ssh-tunneling(AI 서버 호출용 host)
    - docker-compose 실행
        - 개발하려는 서비스는 로컬 소스코드 bind-mount
        - 여타 서비스들 registry에서 이미지 가져와 컨테이너 실행
        - DB들은 종류 무관 local containers 활용

- AI팀

    - GPU 인스턴스 실행 및 접속
    - 소스코드 pull / 의존성 설치
        - DB 컨테이너 활용 등을 위해 docker-compose로 실행
    - local에서 vs-code 접속용 host 제공


### 안정화 버전 AI 서버

특정 branch (e.g. release) CICD로 build 된 Image 및 local DB containers로 구성된 도커 컴포즈 실행
