#!/bin/bash -l
# T03 剩余两个视频模型的权重下载（纯 CPU，不需要 DCU → 用 hx1hcnormal，避免占算力卡）
# Wan2.1-I2V-14B-480P 82.3G → HY-OmniWeaving 55.3G
#SBATCH -p hx1hcnormal
#SBATCH -N 1
#SBATCH -c 8
#SBATCH -t 12:00:00
#SBATCH -J dl-t03
#SBATCH -o /public/home/scnethr2601a10/work/dl-%j.out
#SBATCH -e /public/home/scnethr2601a10/work/dl-%j.err
set -uo pipefail
echo "== node $(hostname) $(date +%T) =="
df -h /public/home/scnethr2601a10 | tail -1
dl() {  # $1=repo  $2=目标目录
  echo "== download $1 -> $2 $(date +%T)"
  python3 - "$1" "$2" <<'PY'
import sys
from modelscope import snapshot_download
repo, dst = sys.argv[1], sys.argv[2]
p = snapshot_download(repo, local_dir=dst)
print("OK", p)
PY
  echo "== rc=$? $(date +%T)  $(du -sh "$2" 2>/dev/null | cut -f1)"
}
dl "Wan-AI/Wan2.1-I2V-14B-480P" /public/home/scnethr2601a10/models/Wan2.1-I2V-14B-480P
dl "Tencent-Hunyuan/HY-OmniWeaving" /public/home/scnethr2601a10/models/HY-OmniWeaving
echo "== ALL DONE $(date +%T) =="
df -h /public/home/scnethr2601a10 | tail -1
