#!/usr/bin/env bash
# Qwen3-ForcedAligner-0.6B on BW1000 + Transformers（T04 词级强制对齐）
# 为什么不用 SGLang/vLLM：官方 align() 接口只在 qwen_asr 包（Transformers 后端）；
# vLLM 亦支持但需 forced_aligner_kwargs，且本任务的输出是"词级时间戳"而非生成文本。
export MODEL_ID="Qwen/Qwen3-ForcedAligner-0.6B"
export MODEL_PATH="/models/FA"
# 2026-11-25 迁移：权重已服务端 cp -a 到 luql 名下（11 文件 / 1.84 GB，diff -r 一致）。
export HOST_MODEL_PATH="/public/home/luql/models/Qwen3-ForcedAligner-0.6B"
export SERVED_NAME="qwen3-forcedaligner-0.6b"

export IMAGE="image.ac.com:5000/dcu/linshp/base/vllm0.20-ubuntu22.04-dtk26.04-py3.10_qwen_asr1.7_bw:1.0.0"
# 2026-11-25 迁移：镜像 tar.gz 已在 luql 名下（与服务端源逐字节一致 + gzip -t 通过），
# 不再依赖已被移出分区的 scnethr2601a10 账号。
export HOST_IMAGE_TAR="/public/home/luql/work/imgstore/vllm0.20-qwen_asr1.7_bw_1.0.0.tar.gz"
export FRAMEWORK="transformers"
export CARD="BW1000"
export PRECISION="bf16"
export PORT=30000

export TASK="align"          # 非 serving 任务：批量跑 30 条，输出词级时间戳
export BATCH_SIZE=1
export LOAD_TIMEOUT=1800
# 2026-11-25 修正：原值指向 scnethr2601a10（已废弃账号）。轮子已服务端 cp -a 到 luql 名下
# （7 文件 / 38,040,896 B，diff -r 一致）。
export WHEELS_HOST="/public/home/luql/wheels/fa310"
