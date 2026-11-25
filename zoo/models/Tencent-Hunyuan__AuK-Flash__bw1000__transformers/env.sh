#!/usr/bin/env bash
# Tencent-Hunyuan/AuK-Flash on BW1000 + Transformers（T03 带参考音语音合成，蒸馏 4 步版）
# 注意：AuK 官方 pin 是 torch>=2.7,<2.8 + transformers>=4.52,<5，
# 而国产卡镜像是 DCU 版 torch 2.9/2.10 + transformers 5.x（PyPI 无 DCU 版 torch 2.7，无法降级）。
# 因此本条目试「忽略 pin、用镜像自带 torch」——能否跑通以实测为准。
export MODEL_ID="Tencent-Hunyuan/AuK-Flash"
export MODEL_PATH="/models/AuKFlash"
# ⚠️ [BLOCKED] 2026-11-25 复核：主权重 `auk_flash.safetensors`（5.7 GiB）在 luql 与
# scnethr2601a10 两个账号下**均已不存在**，本条目当前无法重跑。下面留空串而不是指向废弃账号，
# 让任何引用它的脚本尽早报错，而不是静默挂载一个不存在的目录。
# 要恢复：本机从 ModelScope 下载（Tencent-Hunyuan/AuK-Flash，8 文件，约 6.3 GiB：
#   auk_flash.safetensors 6122209092 B + vae.safetensors 637322604 B + 5 个小文件），
# 传到 /public/home/luql/models/AuK-Flash/ 后把本行改回该路径。
# 注意本机 /tmp 是 tmpfs 只有 5.8G，放不下 5.7 GiB，要下到别的目录（磁盘 / 有 798G）。
export HOST_MODEL_PATH=""
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
# 2026-11-25 修正：原值指向 scnethr2601a10（已废弃账号）。luql 名下已有同一套，
# 53 文件 / 103.1 MiB 且文件名逐一相同，直接改指。
export WHEELS_HOST="/public/home/luql/wheels/auk-fix"
# 检查点文件名（AuK 是 auk_base.safetensors，Flash 是 auk_flash.safetensors，同目录带独立 vae.safetensors）
export CKPT_NAME="auk_flash.safetensors"
# 【2026-11-03】原 auk-bin/ 里放的是 cp312 轮子，而镜像是 py3.10，pip 直接拒装 →
# 120 条全失败在 `ModuleNotFoundError: No module named 'librosa'`。
# 现改为按 --python-version 310 --platform manylinux2014_x86_64 重新下载的 cp310 轮子，
# 单一目录（纯 Python + 二进制混放），不再需要 torchcodec（torchaudio.load 已被 soundfile 替掉）。
export WHEELS_BIN_HOST="/public/home/luql/wheels/auk-fix"
# 2026-11-25 修正：原值指向 scnethr2601a10。luql/src/AuK-src 已有同一份
# （2026-11-25 迁移，diff -r 一致）。
export AUK_SRC_HOST="/public/home/luql/src/AuK-src"
