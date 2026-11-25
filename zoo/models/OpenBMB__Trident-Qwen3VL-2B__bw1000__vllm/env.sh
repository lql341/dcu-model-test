#!/usr/bin/env bash
# OpenBMB/Trident-Qwen3VL-2B on BW1000 + vLLM 0.20.0（T02 混合模态检索嵌入）
# 为什么用 vLLM 而不是 SGLang：SGLang 0.5.10rc0 的 qwen3_vl.py 只注册
# Qwen3VLForConditionalGeneration，没有 Qwen3VLForEmbedding，启动即报
#   ValueError: 'Qwen3VLForEmbedding' is not a registered model
export MODEL_ID="OpenBMB/Trident-Qwen3VL-2B"
export MODEL_PATH="/models/Trident"
# 2026-11-25 修正：原值指向 scnethr2601a10/models/Trident-Qwen3VL-2B，该路径实测 ABSENT
# （该账号 2026-11-07 已被移出分区）。权重的实际位置是 luql 名下（15 文件 / 3.98 GiB），
# 与 __transformers 条目一致。
export HOST_MODEL_PATH="/public/home/luql/models/Trident-Qwen3VL-2B"
export SERVED_NAME="trident-qwen3vl-2b"

export IMAGE="image.ac.com:5000/dcu/linshp/base/vllm0.20-ubuntu22.04-dtk26.04-py3.10_qwen_asr1.7_bw:1.0.0"
# 2026-11-25 迁移：镜像 tar.gz 已在 luql 名下（与服务端源逐字节一致 + gzip -t 通过），
# 不再依赖已被移出分区的 scnethr2601a10 账号。
export HOST_IMAGE_TAR="/public/home/luql/work/imgstore/vllm0.20-qwen_asr1.7_bw_1.0.0.tar.gz"
export FRAMEWORK="vllm"
export CARD="BW1000"
export PRECISION="bf16"
export PORT=30000

export TP=1
export MEM_FRAC=0.6
export MAX_LEN=8192
export MAX_NUM_SEQS=64
export LOAD_TIMEOUT=1800

export EXTRA_ARGS="--trust-remote-code --dtype bfloat16 --max-num-seqs $MAX_NUM_SEQS"
