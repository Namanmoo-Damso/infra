## Log


- 2025-12-29

    - terraform 적용 테스트

        > [!NOTE] why terraform? - 수동관리의 문제점
        >
        > - 인프라 재현이 어려움
        > - 단순하고 반복적인 작업인데 시간도 오래걸림
        > - 휴먼 에러가 발생할 가능성이 높음

        - ec2 인스턴스 생성/제거
        - Elastic IP를 함께 생성하고 각 ec2에 attach 해주기




- 2026-01-06

    - 모듈화



## 실행방법


```sh
# 새로운 모듈 추가
terraform init

# 확인
terraform plan

# 리소스 생성
terraform apply

# output 출력
terraform output

# 리소스 제거
terraform destroy

# 특정 모듈만 적용(root module에 module key에 이름)
terraform apply -target=module.<module_name>
# e.g. terraform destroy -target=module.my_cpu_test
```

  - `<module_name>` 예시
      - File Path: terraform/main.tf, 17:17
        ```terraform
        module "cpu_test" {
        ```




## 사용하는 AMI 상세설명

> [!NOTE]
>
>  AMI는 EC2 인스턴스의 템플릿으로, 다음을 포함해요:
>  - OS: Linux (Amazon Linux, Ubuntu, CentOS 등), Windows 등. AMI 이름으로 OS를 선택해요 
>    (예: "amzn2"는 Amazon Linux 2, "ubuntu"는 Ubuntu).
>  - 애플리케이션/소프트웨어: 미리 설치된 패키지 (예: 웹 서버, 데이터베이스).
>  - 설정: 루트 볼륨 크기, 네트워크 설정, 부트스트랩 스크립트 등.
>  - 하드웨어 가상화: HVM (Hardware Virtual Machine)이나 PV (Paravirtual).


### general(None-GPU)

```json
{
 "PlatformDetails": "Linux/UNIX",
 "UsageOperation": "RunInstances",
 "BlockDeviceMappings": [
   {
     "Ebs": {
       "DeleteOnTermination": true,
       "SnapshotId": "snap-03caf7c59107e3143",
       "VolumeSize": 8,
       "VolumeType": "gp3",
       "Encrypted": false
     },
     "DeviceName": "/dev/sda1"
   },
   {
     "DeviceName": "/dev/sdb",
     "VirtualName": "ephemeral0"
   },
   {
     "DeviceName": "/dev/sdc",
     "VirtualName": "ephemeral1"
   }
 ],
 "Description": "Canonical, Ubuntu Minimal, 24.04, amd64 noble image",
 "EnaSupport": true,
 "Hypervisor": "xen",
 "ImageOwnerAlias": "amazon",
 "Name": "ubuntu-minimal/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-minimal-20251210",
 "RootDeviceName": "/dev/sda1",
 "RootDeviceType": "ebs",
 "SriovNetSupport": "simple",
 "VirtualizationType": "hvm",
 "BootMode": "uefi-preferred",
 "DeprecationTime": "2027-12-10T13:12:35.000Z",
 "ImdsSupport": "v2.0",
 "FreeTierEligible": true,
 "ImageId": "ami-0c447e8442d5380a3",
 "ImageLocation": "amazon/ubuntu-minimal/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-minimal-20251210",
 "State": "available",
 "OwnerId": "099720109477",
 "CreationDate": "2025-12-10T13:12:35.000Z",
 "Public": true,
 "Architecture": "x86_64",
 "ImageType": "machine"
}
```


### GPU for AI pipeline


`ami-09399dbfdc84fada6`은 AWS에서 제공하는 **Deep Learning OSS Nvidia Driver AMI (Ubuntu 22.04)** 입니다.
이 AMI는 GPU 인스턴스를 위해 설계되었으며 다음과 같은 주요 특징을 가집니다.


- 주요 특징
    - **사전 설치된 드라이버 및 툴킷**: NVIDIA 커널 드라이버, CUDA Toolkit, cuDNN, NCCL 및 Fabric Manager가 이미 설치 및 구성되어 있어 설정 시간을 대폭 단축합니다.
    - **최적화된 환경**: AWS의 다양한 GPU 가속 인스턴스 성능을 최대로 활용할 수 있도록 튜닝되어 있습니다.
    - **Docker 및 가속기 지원**: NVIDIA Container Toolkit(nvidia-docker2)이 포함되어 있어 컨테이너 환경에서도 GPU 접근이 용이합니다.
    - **오픈 소스 소프트웨어(OSS)**: NVIDIA 드라이버의 오픈 소스 커널 모듈 버전을 사용하여 투명성과 운영 체제 호환성을 높였습니다.
    - `nvidia-smi` 명령어를 통해 별도의 설치 작업 없이 즉시 GPU 상태를 확인할 수 있는 준비된 환경을 제공받게 됩니다.

- 주요 구성 요소
    - **OS**: Ubuntu 22.04 LTS
    - **CUDA**: 최신 버전의 가속 라이브러리 포함
    - **Python**: 다양한 딥러닝 프레임워크를 위한 가상 환경 지원

