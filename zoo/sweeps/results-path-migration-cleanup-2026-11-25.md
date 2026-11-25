# 2026-11-25 收口：路径迁移到 luql + 家目录清理 502 GB

## 为什么做

上一版 HANDOFF（2026-11-22）把 `HOST_IMAGE_TAR` 修对了，但 **`HOST_MODEL_PATH` / `HOST_CLI_TAR` /
`*_SRC_HOST` 仍大量指向 `scnethr2601a10`** —— 该账号 2026-11-07 已被移出 `hx1hdnormal` 的
AllowAccounts（见 `docs/ARCHIVE-SUMMARY.md`）。文件当时还能读，所以没暴露成故障，但属于随时会断的依赖。

同时家目录已用到 **94%（可用仅 94 GB）**，而 `models/` 下躺着 502 GB 零引用权重。

## 一、先证明「那个账号还能读，但删不了」

作业 1211731（脚本 `sweeps/xacct-probe-2026-11-25.sh`，1 卡 43 s，节点 a14r3n18）+
作业 1211883（修正版，节点 f11r1n04）：

```
/public/home/scnethr2601a10        drwx---r-x  scnethr2601a10
/public/home/scnethr2601a10/zoo-images   drwxr-xr-x  scnethr2601a10
READABLE  7.9G  .../zoo-images/mimo-sglang-bw10000_1.1.1.tar.gz
READABLE  8.7G  .../zoo-images/vllm0.20-qwen_asr1.7_bw_1.0.0.tar.gz
READABLE  31G   /public/home/luql/work/imgstore/vllm021.tar
READABLE  2.8K  .../AuK-src/pyproject.toml
READABLE  23K   .../Wan2.1-src/generate.py
```

判据：`others` 是 `r-x` → **luql 能读、不能删**。这解释了此前"一直能用"，也说明不能靠"还能跑"来判断安全。

> 顺带修正一个自己的 bug：第一版探针在 `set -u` 下用了未绑定的 `$2`，跑到文件读取段就退出
> （`行40: $2: 未绑定的变量`）。重跑前已修掉。

## 二、迁移（服务端 `cp -a`，逐项校验）

不用上传下载（10 MB/s 太慢），全部在同一文件系统内 `cp -a`。

| 内容 | 体积 | 校验结果 |
| --- | --- | --- |
| AuK-src | 30.35 MB（90 文件） | 文件字节总和 MATCH、`diff -r` rc=0 |
| Wan2.1-src | 5.26 MB（51 文件） | 同上 |
| MiMo-V2.6-Distill-Qwen-9B | 18.85 GB（18 文件） | 同上 |
| MiniMax-Music3 | 57.35 GB（89 文件） | 同上 |
| Qwen3-ASR-1.7B | 4.70 GB（13 文件） | 同上 |
| Qwen3-ForcedAligner-0.6B | 1.84 GB（11 文件） | 同上 |
| mimo-sglang 1.1.1 镜像 | 7.89 GiB | 字节 MATCH + sha256(前 512 MiB) 一致 + `gzip -t` OK |
| vllm0.20 镜像 | 8.68 GiB | 同上 |
| music3 镜像 | 12.79 GiB | 同上 |

> `du -sb` 首次比对 AuK-src 差 4096 B（正好一个块），复查是**目录元数据块**的口径差异，
> 常规文件字节总和完全相同。教训：校验源码用 `find -type f -printf '%s'` 求和 + `diff -r`，
> 不要用 `du -sb` 比目录。

### 附带解决的一个疑虑

`podman load -i` 能否直接读 `.tar.gz`？11 个条目都这么写，但没人实测过。
作业 1212004（610 s）实证 **PASS**：

```
Loaded image: image.ac.com:5000/dcu/linshp/base/mimo-sglang-bw10000:1.1.1
rc=0  elapsed=610s
RESULT_A=PASS
```

所以那 11 个条目的写法是对的，不需要改成 `gunzip -c | podman load`。

## 三、清理（用户确认只删 A 组零引用孤儿）

作业 1212575：

```
删除前：1.4T 已用 / 94G 可用 / 94%
  models/DeepSeek-V4.1-Flash-1017   476G
  models/Qwen2.5-7B-Instruct         15G
  models/vjepa2                      11G
删除后：856G 已用 / 595G 可用 / 60%
```

判据（删前逐项 grep 过）：

| 目录 | 判据 |
| --- | --- |
| DeepSeek-V4.1-Flash-1017 | 无 DeepSeek 条目；INDEX/README 未列；HANDOFF 零提及；deepinfer 支线自身结论是"可行性未验证" |
| Qwen2.5-7B-Instruct | 全仓库 grep 0 命中 |
| vjepa2 | 全仓库 grep 0 命中 |

删后复查：15 个被引用的模型目录全部完好（AuK 6.3G / HY-OmniWeaving 74G / HY-World 4.8G /
Kimi 92G / MiMo 18G / Music3 54G / Qwen2.5-Omni 12G / ASR 4.4G / FA 1.8G / Qwen3-VL 17G /
Qwen-Image 31G / Recon2Reason 8.3G / RoboBrain 17G / Trident 4.0G / Wan 77G）。

## 四、env.sh 改动清单

| 文件数 | 改动 |
| --- | --- |
| 18 | `HOST_IMAGE_TAR` / `HOST_CLI_TAR`：`scnethr2601a10/zoo-images/` → `luql/work/imgstore/` |
| 6 | `HOST_MODEL_PATH`：`scnethr2601a10/models/` → `luql/models/` |
| 2 | `AUK_SRC_HOST` / `WAN_SRC_HOST`：已消失的 `archive/...` → `luql/src/` |
| 2 | Trident 的 `HOST_MODEL_PATH`：原指向**根本不存在的** `scnethr2601a10/models/Trident-Qwen3VL-2B` → `luql/models/` |
| 2 | Recon2Reason / RoboBrain 的 `HOST_CLI_TAR`：原为 `""`（但压测段仍用 CLI 镜像）→ 指向现存副本 |
| 1 | AuK-Flash 的 `HOST_ENCODER_PATH`：不存在的 scnethr 路径 → `luql/models/Qwen2.5-Omni-3B` |
| 10 | README 里重复的「镜像归档在 `archive/...`」模板句 → 改为 `luql/work/imgstore/` |

## 五、遗留（未做，按用户指示"权重不用迁"）

| 项 | 状态 |
| --- | --- |
| `AuK-Flash` 主权重 `auk_flash.safetensors` | **两账号均无，确认丢失**；env.sh 已加醒目注释，条目当前不可重跑 |
| Music3 `CONDITIONS_HOST` | 指向的 scnethr 路径实测 ABSENT；仓库内有 `conditions/music3.jsonl` 可替代 |
| Music3 `HARNESS_HOST`、ForcedAligner/AuK-Flash 的 `WHEELS_HOST`、AuK-Flash 的 `AUK_SRC_HOST` | 仍指废弃账号（可读，未迁） |
| `HY-World-2.0` 镜像 | 从未归档 + Harbor 不可达 → 不可重跑（MISSING.md 已标注） |

## 六、复现

```bash
S="${SCNET_PY:-$HOME/Downloads/agent/skills/scnet-hpc/scripts/scnet.py}"
# 队列余量
python3 "$S" --region 20091 resource-summary
# 配额（期望 595 GB 可用 / 60%）
python3 "$S" --region 20091 quota
# 镜像是否齐（期望 4 个，共 60 GB）
python3 "$S" --region 20091 files --path /public/home/luql/work/imgstore
# 权重是否齐（期望 15 个被引用目录）
python3 "$S" --region 20091 files --path /public/home/luql/models
```

---

## 七、二次收口：残留清零（同日稍后）

第一轮留了 6 处运行时路径仍指向 `scnethr2601a10`。本轮全部处理完，`grep '^export .*scnethr2601a10'`
在 `models/*/env.sh` 中**零命中**，66 处运行时路径全指向 `/public/home/luql`。

| 资产 | 体积 | 校验 |
| --- | --- | --- |
| `wheels/fa310` | 7 文件 / 38,040,896 B | `diff -r` 一致 |
| `work/music3-hygon` | 79 文件 / 513,701 B | 逐文件 `cmp` 0 差异 |
| `work/official-conds/music3.jsonl` | 53,128 B | `cmp` 完全一致 |
| `wheels/auk-fix` | 53 文件 / 103.1 MiB | 与源**同名同大小**，未复制（luql 已有），直接改指 |
| `AuK-src` | 30.35 MB | 已在第一轮迁到 `luql/src/`，本轮仅改指针 |

### 更正上一版的一个误判

第一轮写「Music3 的 `CONDITIONS_HOST` 指向的 `music3.jsonl` 实测 ABSENT」——**这是错的**。
`scnet.py files --path <文件路径>` 只能列**目录**，对文件会返回 `911020 File does not exist`。
我把这个报错当成了"文件不存在"。实际该文件存在（53,128 B），与仓库内
`conditions/music3.jsonl`（60 条条件）是同一份。

**教训**：判断单个文件是否存在，用 `files --path <父目录>` 看列表，或 `download` 试取；
不要拿 `files` 直接指向文件然后按报错下结论。

### `music3-hygon` 的 diff 差异不是问题

`diff -r` 报 12 行，但**逐文件 `cmp` 为 0 差异**。原因：目录里有 6 个本来就断的符号链接
（`runtime/backbone/*.safetensors -> /models/Music3/...`，那是**容器内**挂载点，在宿主机上本就不存在），
`diff` 对两边各报一次、共 12 行。

已核查全部 10 个符号链接，**没有任何指向原账号的绝对路径**：

```
.venv/bin/python -> python3                     相对
.venv/bin/python3 -> /usr/bin/python3            绝对，但系统路径
.venv/bin/python3.10 -> python3                  相对
.venv/lib64 -> lib                               相对
runtime/backbone/*.safetensors -> /models/Music3/...   容器内挂载点（宿主机本就断链）
server.log -> logs/server-20261105T025506Z.log   相对
```

### 一处操作失误（已清理）

我一度误判「要把 AuK-Flash 权重下回来」，往 `/tmp/aukflash` 下载 5.7 GiB 主权重。
本机 `/tmp` 是 **tmpfs 只有 5.8 GB**，下到 2.4 GB 就涨到 98%。已 `pkill` + `rm -rf` 清理，
`/tmp` 回到 58%（剩余 3.4 GB 是原有的 `dcuenv` 2.5G 与 `py310env` 819M，非本次产生）。

**结论：AuK-Flash 权重按用户指示不补**，`HOST_MODEL_PATH=""` + `submit.slurm` 显式拦截
（打印 `MODEL_WEIGHTS_MISSING` 退出 1），恢复步骤写在 env.sh 顶部注释里。
