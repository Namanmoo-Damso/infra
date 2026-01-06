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
