FROM python:3.9-slim

# 1. SSH 클라이언트 설치 (scp, ssh 명령어를 위해 필수)
RUN apt-get update && apt-get install -y openssh-client && rm -rf /var/lib/apt/lists/*

# 2. AWS 제어를 위한 boto3 라이브러리 설치
RUN pip install boto3

WORKDIR /app

# 3. ec2 인스턴스를 통제하는 스크립트
COPY script.py .

# 4. 실행 (기본값)
CMD ["python", "script.py"]
