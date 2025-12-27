import os
import subprocess
import sys
import time

import boto3


def get_clean_env(key, default=None):
    val = os.getenv(key, default)
    if val:
        # '#' 문자를 기준으로 자르고 앞뒤 공백 제거
        return val.split("#")[0].strip()
    return val


# 환경 변수 로드
ACCESS_KEY = get_clean_env("AWS_ACCESS_KEY_ID")
SECRET_KEY = get_clean_env("AWS_SECRET_ACCESS_KEY")
REGION = get_clean_env("AWS_REGION")
INSTANCE_ID = get_clean_env("INSTANCE_ID")
ACTION = get_clean_env("ACTION")

# SSH 접속 정보 추가
SSH_KEY_PATH = get_clean_env("SSH_KEY_PATH")
SSH_USER = get_clean_env("SSH_USER")  # EC2 유저 (ubuntu, ec2-user 등)
DEPLOY = get_clean_env("DEPLOY", "false").lower() == "true"  # 배포 여부

if not all([ACCESS_KEY, SECRET_KEY, INSTANCE_ID]):
    print("Error: 필수 환경 변수가 설정되지 않았습니다.")
    sys.exit(1)

ec2 = boto3.client(
    "ec2",
    aws_access_key_id=ACCESS_KEY,
    aws_secret_access_key=SECRET_KEY,
    region_name=REGION,
)


def get_public_ip():
    response = ec2.describe_instances(InstanceIds=[INSTANCE_ID])
    try:
        return response["Reservations"][0]["Instances"][0]["PublicIpAddress"]
    except (KeyError, IndexError):
        return None


def wait_for_ssh(ip):
    print("⏳ Waiting for SSH to be ready...")
    retries = 0
    while retries < 20:
        try:
            # nc(netcat) 등으로 포트 체크를 할 수도 있지만, 간단히 ssh 연결 시도
            subprocess.check_call(
                [
                    "ssh",
                    "-o",
                    "ConnectTimeout=5",
                    "-o",
                    "StrictHostKeyChecking=no",
                    "-i",
                    SSH_KEY_PATH,
                    f"{SSH_USER}@{ip}",
                    "echo ready",
                ],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            print("✅ SSH is ready!")
            return True
        except subprocess.CalledProcessError:
            time.sleep(3)
            retries += 1
            print(".", end="", flush=True)
    return False


def provision_server(ip):
    print(f"🛠️ Provisioning server at {ip}...")

    # 1. setup.sh 파일 전송 (SCP)
    try:
        subprocess.check_call(
            [
                "scp",
                "-o",
                "StrictHostKeyChecking=no",
                "-i",
                SSH_KEY_PATH,
                "setup.sh",  # Dockerfile에서 COPY 했으므로 현재 경로에 있음
                f"{SSH_USER}@{ip}:/home/{SSH_USER}/setup.sh",
            ],
            stdout=subprocess.DEVNULL,
        )
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to transfer setup script: {e}")
        return False

    # 2. 원격지에서 setup.sh 실행 (SSH)
    print("🛠️ Running setup script on remote EC2...")
    try:
        subprocess.check_call(
            [
                "ssh",
                "-o",
                "StrictHostKeyChecking=no",
                "-i",
                SSH_KEY_PATH,
                f"{SSH_USER}@{ip}",
                "chmod +x setup.sh && ./setup.sh",  # 실행 권한 주고 실행
            ]
        )
        print("✅ Provisioning complete!")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Provisioning failed: {e}")
        return False


def deploy_services(ip):
    print(f"🚀 Deploying docker-compose.yml to {ip}...")

    # 1. docker-compose.yml 파일 전송 (SCP)
    try:
        subprocess.check_call(
            [
                "scp",
                "-o",
                "StrictHostKeyChecking=no",
                "-i",
                SSH_KEY_PATH,
                "docker-compose.yml",
                f"{SSH_USER}@{ip}:/home/{SSH_USER}/docker-compose.yml",
            ]
        )
        print("✅ File transfer complete.")
    except subprocess.CalledProcessError as e:
        print(f"❌ SCP failed: {e}")
        return

    # 2. 원격지에서 Docker Compose 실행 (SSH)
    print("🚀 Starting services on remote EC2...")
    try:
        subprocess.check_call(
            [
                "ssh",
                "-o",
                "StrictHostKeyChecking=no",
                "-i",
                SSH_KEY_PATH,
                f"{SSH_USER}@{ip}",
                "docker compose up -d",  # 혹은 docker-compose up -d
            ]
        )
        print("✅ Services started successfully!")
    except subprocess.CalledProcessError as e:
        print(f"❌ Remote execution failed: {e}")


def start_instance_sync():
    print(f"🚀 Starting instance {INSTANCE_ID}...")
    try:
        ec2.start_instances(InstanceIds=[INSTANCE_ID])
        waiter = ec2.get_waiter("instance_running")
        print("⏳ Waiting for instance to be running...")
        waiter.wait(InstanceIds=[INSTANCE_ID])

        # IP 조회
        ip = get_public_ip()
        print(f"✅ Instance is RUNNING! Public IP: {ip}")

        # [추가됨] 쉘 스크립트가 낚아챌 수 있도록 접속 정보를 특정 포맷으로 출력
        print(f"__SSH_CONNECT_TARGET__={SSH_USER}@{ip}")

        if ip and wait_for_ssh(ip):
            provision_server(ip)
        else:
            print("❌ SSH connection timed out.")

        # if DEPLOY and ip:
        #     if wait_for_ssh(ip):
        #         deploy_services(ip)
        #     else:
        #         print("❌ SSH connection timed out.")

    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)


def stop_instance_sync():
    print(f"🛑 Stopping instance {INSTANCE_ID}...")
    try:
        ec2.stop_instances(InstanceIds=[INSTANCE_ID])
        waiter = ec2.get_waiter("instance_stopped")
        print("⏳ Waiting for instance to be stopped...")
        waiter.wait(InstanceIds=[INSTANCE_ID])
        print("✅ Instance is STOPPED!")
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    if ACTION == "start":
        start_instance_sync()
    elif ACTION == "stop":
        stop_instance_sync()
    else:
        print(f"Unknown ACTION: {ACTION}")
