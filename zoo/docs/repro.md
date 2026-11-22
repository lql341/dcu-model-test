# 从零重建一个条目（端到端）

> **2026-11-22 重写**。旧版本基于 `ssh zzeshell-hz1` + `sbatch` + `/public/home/luql/archive/zoo-dcu-2026-11/`，
> 这三样现在**全部不可用**（SSH 报 `Permission denied (publickey)`、集群无外网、
> archive 目录已不可见）。旧版留档在 git 历史里（`git log --follow docs/repro.md`）。

目的：**换机器 / 上游镜像被删 / 临时账号回收**之后，仍能把任意条目跑到「出真产物」。

所需素材：**本仓库**（脚本 + 日志 + 基准）+ **权重**（ModelScope 重下）+ **镜像**（本地 tar 归档）。

---

## 0. 前置检查（每次都做，2 分钟）

```bash
# ① 定位 scnet.py 并确认认证已配（没配就先 `python3 $S init`）
S="${SCNET_PY:-$HOME/Downloads/agent/skills/scnet-hpc/scripts/scnet.py}"
python3 "$S" --region 20091 doctor

# ② 看队列有无空闲节点
python3 "$S" --region 20091 resource-summary

# ③ 确认镜像归档还在（这步最关键，Harbor 已不可达）
ls -lh /public/home/luql/work/imgstore/vllm021.tar
ls -lh /public/home/scnethr2601a10/zoo-images/*.tar.gz
```

任何一步失败先解决，不要往下走。

---

## 1. 准备权重

集群无外网，**必须本机下载后上传**（gotcha #60）：

```bash
# 本机：按文件清单逐个下载（ModelScope），核对每个文件字节数
#   清单 API: https://modelscope.cn/api/v1/models/<org>/<model>/repo/files
#   单文件:   https://modelscope.cn/models/<org>/<model>/resolve/master/<filename>
mkdir -p /tmp/dl_stage/model && cd /tmp/dl_stage/model
#   ... curl -L -C - 逐个下载 ...

# 上传到集群（upload 只收单文件）
DEST=/public/home/luql/models/<模型名>/
python3 "$S" --region 20091 mkdir "$DEST"
for f in /tmp/dl_stage/model/*; do
  python3 "$S" --region 20091 upload --cover "$f" "$DEST"
done

# 校验远端字节数
python3 "$S" --region 20091 files --path "$DEST" | python3 -c "
import json,sys; d=json.load(sys.stdin)
print(len(d['files']),'files', round(sum(f['size'] for f in d['files'])/2**30,2),'GiB')"

rm -rf /tmp/dl_stage        # 本机不留副本
```

已有权重可直接复用：`python3 "$S" --region 20091 files --path /public/home/luql/models` 列一下。

---

## 2. 准备镜像

Harbor 不可达（gotcha #62），从本地 tar 加载。`env.sh` 里必须设：

```bash
export HOST_IMAGE_TAR="/public/home/luql/work/imgstore/vllm021.tar"          # 服务镜像
export HOST_CLI_TAR=""   # vLLM 条目用同镜像内 vllm bench serve，不需要 CLI 镜像
```

`container/submit.slurm` 的加载顺序是「本地 tar → 失败才 pull」，设对了就不依赖网络。

**空间要求**：单个镜像 load 后约 30 GB，`/tmp` 需要 ≥40 GB。
本分区各节点在 21–320 GB 间波动，`submit.slurm` 里已有 `exit 42` 换节点逻辑。
**双镜像共存需 145 GB，实测反复失败**——所以 vLLM 条目改用同镜像内压测（gotcha #62/#63）。

---

## 3. 打 tar 上传并提交

```bash
# 打包条目（upload 只收单文件）
cd /path/to/dcu-model-test/zoo
tar czf /tmp/entry.tgz -C models/<条目目录> .

# 上传
WORK=/public/home/luql/work/<条目名>
python3 "$S" --region 20091 mkdir  "$WORK"
python3 "$S" --region 20091 upload --cover /tmp/entry.tgz "$WORK/"

# 写一个入口脚本（解包 + 执行 submit.slurm），一起传上去
cat > /tmp/entry.sh <<'EOM'
#!/bin/bash
set -uo pipefail
WORK=/public/home/luql/work/<条目名>
rm -rf "$WORK/repo" && mkdir -p "$WORK/repo"
tar xzf "$WORK/entry.tgz" -C "$WORK/repo"
cd "$WORK/repo" && export SLURM_SUBMIT_DIR="$WORK/repo"
bash container/submit.slurm
EOM
python3 "$S" --region 20091 upload --cover /tmp/entry.sh "$WORK/"

# 提交作业（--dcus 最小 1；--cpus 用 16）
python3 "$S" --region 20091 submit --name <条目名> --queue hx1hdnormal \
  --nodes 1 --dcus 1 --cpus 16 --memory 32GB --walltime 03:00:00 \
  --work-dir "$WORK" --command "bash $WORK/entry.sh 2>&1 | tee $WORK/run.out"

# 等待与取日志
python3 "$S" --region 20091 --timeout 400 wait <JID>
python3 "$S" --region 20091 download --cover "$WORK/run.out" /tmp/run.out
```

> ⚠️ `download` 不加 `--cover` 时若本地文件已存在会**静默返回旧文件**，
> 排查时会看到过期内容。取日志一律加 `--cover`。

---

## 4. 判据：怎么算真的跑通了

| 检查 | 期望 |
| --- | --- |
| `run.out` 里 `[host] server up after` | 有数值（说明服务起来了） |
| `smoke.log` 的 `/health` | HTTP 200 |
| `smoke.log` 里有图像请求 | 返回正确内容（不是 500） |
| `bench/summary.md` | 有 6 行数据 |
| `bench_vllm.sh` 的有效性校验 | `all valid` |
| `verify.py` | 有官方基线才出分；没有则 `[BLOCKED]`（**这是对的，不要绕过**） |

只看容器退出码会被 `verify.py` 的 `[BLOCKED]`（exit 1）掩盖成 `rc=2`，
**必须看上面这几项实际产物**。

---

## 5. 回收产物入库

```bash
for f in logs/env.log logs/smoke.log bench/summary.md bench/round1.jsonl bench/round2.jsonl; do
  python3 "$S" --region 20091 download --cover "$WORK/repo/$f" "models/<条目>/$f"
done
# 服务端日志通常较大，压缩后入库
python3 "$S" --region 20091 download --cover "$WORK/vllm-logs-<JID>.txt" /tmp/srv.log
gzip -c /tmp/srv.log > models/<条目>/logs/server.log.gz
```

然后填 `meta.json`（`cold_start_s`、`throughput` 六项）与 README 对应章节，
最后 `./tools/publish.sh "feat(<条目>): 新增"`。

---

## 6. 常见失败

| 现象 | 原因 | 解法 |
| --- | --- | --- |
| `NOT_ENOUGH_SPACE` + `exit 42` | 节点 `/tmp` 不足 | 重新 submit（会换节点），或等空间释放 |
| `IMAGE_UNAVAILABLE` | 本地 tar 路径错 / tar 里 tag 与 `IMAGE` 不一致 | `tar xOf <tar> repositories` 核对 |
| `no space left on device` 发生在 load 第二个镜像 | 双镜像共存需 145 GB | 改用同镜像压测（gotcha #62） |
| `Repo id must be in the form 'repo_name'` | 压测容器漏挂 `-v $HOST_MODEL_PATH:/models/M:ro` | 补挂载 |
| `OpenAI Chat Completions API URL must end with` | `--backend openai-chat` 默认 endpoint 错 | 加 `--endpoint /v1/chat/completions` |
| `--random-input-len is too small` | `--random-range-ratio 1` 语义变了 | 去掉该参数 |

更多见 `docs/gotchas.md`（63 条）。