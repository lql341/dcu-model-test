#!/usr/bin/env bash
# Qwen/Qwen-Image-2.1-Turbo on BW1000 + Diffusers（T03 文生图）
# 官方固定条件：输出 2048×2048，60 输入 × 3 seed(42/2026/1234) = 180 条目
# 注意：官方模型卡要求 transformers>=5.17.0，但 PyPI 当前最高 5.9.0 —— 该版本不存在，
#       故用镜像自带 5.8.1 + diffusers 0.42.1（已内置 QwenImage21Pipeline）实测。
export MODEL_ID="Qwen/Qwen-Image-2.1-Turbo"
export MODEL_PATH="/models/QwenImage"
export HOST_MODEL_PATH="/public/home/luql/models/Qwen-Image-2.1-Turbo"

export IMAGE="image.ac.com:5000/dcu/linshp/base/mimo-sglang-bw10000:1.1.1"
# 2026-11-25 迁移：镜像 tar.gz 已在 luql 名下（与服务端源逐字节一致 + gzip -t 通过），
# 不再依赖已被移出分区的 scnethr2601a10 账号。
export HOST_IMAGE_TAR="/public/home/luql/work/imgstore/mimo-sglang-bw10000_1.1.1.tar.gz"
export FRAMEWORK="diffusers"
export CARD="BW1000"
export PRECISION="bf16"
export PORT=0

export WIDTH=2048
export HEIGHT=2048
export NFE=8                 # Turbo 版内置 8 步日程；只设 num_inference_steps 不会覆盖，需传 sigmas
export WHEELS_HOST="/public/home/luql/wheels/qi2"   # qi2 的 huggingface_hub 是 1.33.0；qi 里是旧的 0.36.2，diffusers 0.41 会 ImportError
export LOAD_TIMEOUT=1800
