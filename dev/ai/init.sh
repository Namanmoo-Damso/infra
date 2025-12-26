#!/bin/bash

echo "Starting AI Infrastructure (Vector DB, RDBMS)..."

# GPU 드라이버 확인 (선택 사항)
if command -v nvidia-smi &> /dev/null; then
    echo "NVIDIA GPU detected."
    nvidia-smi
else
    echo "Warning: No NVIDIA GPU detected. Ensure you are on the GPU instance if training/inference is needed."
fi

docker-compose up -d

echo "Infrastructure is ready."
echo "Please activate your python environment and run the pipeline."
echo "VS Code Remote Host is ready for connection."
