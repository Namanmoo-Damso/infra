

```sh
tree secrets -J
secrets
├── access-keys
│   ├── docker-ec2-control_sy_accessKeys.csv  # ec2 dev server 접근용 발급 2025-12-28
│   └── manage_infra_sy_accessKeys.csv # terraform 전용 2025-12-29
├── README.md
└── ssh-keys
    └── dev-server.pem # ec2 dev server 접근용 ssh key

3 directories, 4 files
```



- access-keys

    - docker-ec2-control_sy_accessKeys.csv  
        - 2025-12-28
        - ec2 dev server 접근용 발급 
        - use case: Local code

    - manage_infra_sy_accessKeys.csv 
        - 2025-12-29
        - terraform 전용
        - use case: Command Line Interface (CLI)



- ssh-keys

    - dev-server.pem 
        - ec2 dev server 접근용



