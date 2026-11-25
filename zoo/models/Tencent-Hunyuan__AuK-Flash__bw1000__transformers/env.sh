#!/usr/bin/env bash
# Tencent-Hunyuan/AuK-Flash on BW1000 + Transformers（T03 带参考音语音合成，蒸馏 4 步版）
# 注意：AuK 官方 pin 是 torch>=2.7,<2.8 + transformers>=4.52,<5，
# 而国产卡镜像是 DCU 版 torch 2.9/2.10 + transformers 5.x（PyPI 无 DCU 版 torch 2.7，无法降级）。
# 因此本条目试「忽略 pin、用镜像自带 torch」——能否跑通以实测为准。
export MODEL_ID="Tencent-Hunyuan/AuK-Flash"
export MODEL_PATH="/models/AuKFlash"
# ⚠️ 2026-11-25 复核：本条目**当前无法重跑**——主权重 `auk_flash.safetensors`（6.1 GB）
# 在 luql 与 scnethr2601a10 两个账号下均已找不到（原值 scnethr2601a10/models/AuK-Flash 实测 ABSENT，
# luql 家目录全量索引中也无该文件）。要重跑需先从 ModelScope 重新下载 6.1 GB 主权重 + 0.6 GB vae。
# 下面保留原路径作为「曾经的位置」，不要当成可用路径引用。
export HOST_MODEL_PATH="/public/home/scnethr2601a10/models/AuK-Flash"
# 编码器权重仍在（已迁移/存在于 luql 名下，18 文件 / 11.17 GiB）；原 scnethr 路径已 ABSENT。
export ENCODER_PATH="/models/Qwen2.5-Omni-3B"
export HOST_ENCODER_PATH="/public/home/luql/models/Qwen2.5-Omni-3B"
export SERVED_NAME="auk-flash"

# 选 SGLang 镜像而非 vLLM 镜像：AuK 的 infer_cli 需要 torchaudio，
# 该镜像自带 DCU 版 torchaudio 2.9.0+das；vLLM 镜像无 torchaudio，而 PyPI 的 torchaudio
# 是 CUDA/CPU 构建，装进去与 DCU 版 torch 不匹配。
export IMAGE="image.ac.com:5000/dcu/linshp/base/mimo-sglang-bw10000:1.1.1"
# 2026-11-25 迁移：镜像 tar.gz 已在 luql 名下（与服务端源逐字节一致 + gzip -t 通过），
# 不再依赖已被移出分区的 scnethr2601a10 账号。
export HOST_IMAGE_TAR="/public/home/luql/work/imgstore/mimo-sglang-bw10000_1.1.1.tar.gz"
export FRAMEWORK="transformers"
export CARD="BW1000"
export PRECISION="bf16"
export PORT=30000

export TASK="tts"
export LOAD_TIMEOUT=1800
export WHEELS_HOST="/public/home/scnethr2601a10/wheels/auk-fix"
# 检查点文件名（AuK 是 auk_base.safetensors，Flash 是 auk_flash.safetensors，同目录带独立 vae.safetensors）
export CKPT_NAME="auk_flash.safetensors"
# 【2026-11-03】原 auk-bin/ 里放的是 cp312 轮子，而镜像是 py3.10，pip 直接拒装 →
# 120 条全失败在 `ModuleNotFoundError: No module named 'librosa'`。
# 现改为按 --python-version 310 --platform manylinux2014_x86_64 重新下载的 cp310 轮子，
# 单一目录（纯 Python + 二进制混放），不再需要 torchcodec（torchaudio.load 已被 soundfile 替掉）。
export WHEELS_BIN_HOST="/public/home/scnethr2601a10/wheels/auk-fix"
export AUK_SRC_HOST="/public/home/scnethr2601a10/AuK-src"
