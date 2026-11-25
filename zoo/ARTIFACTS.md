# SCNet 侧原始产物位置

> ⚠️ **本文是 2026-11-09 的历史记录，路径大多已失效。**
> **现状（2026-11-25）**：① 代码与经验 → GitHub `lql341/dcu-model-test`（`zoo/` 子目录，Apache-2.0）；
> ② 产物与镜像 → 原 `archive/` 目录与 `~/Downloads/pi-test/archive/` **均已不可见**；
> **镜像与源码/权重现已全部收拢到 `luql` 名下**（`luql:~/work/imgstore/`、`~/src/`、`~/models/`、
> `~/wheels/`），运行时不再依赖 `scnethr2601a10`（见 `HANDOFF.md` §2.7）；
> ③ 原集群账号 `scnethr2601a10` 已失效（2026-11-07 移出分区），其目录仍可读但**不要再依赖**。
> 还原步骤见 **[docs/repro.md](docs/repro.md)**（2026-11-22 已重写为 OpenAPI 方式）。

所有数据目前落在 `luql` 账号名下。**GitHub 是本仓库的权威副本**，下列路径仅用于回溯。

## 郑州集群（BW1000）——历史布局（账号 `scnethr2601a10`，已废弃）

> 下面这棵树是 2026-11-09 当时的布局，**已不是当前布局**。当前布局见
> `HANDOFF.md` §2.7：权重在 `luql:~/models/`、镜像在 `luql:~/work/imgstore/`、
> 源码在 `luql:~/src/`、轮子在 `luql:~/wheels/`。

```
/public/home/scnethr2601a10/
├── models/
│   ├── Kimi-Linear-48B-A3B-Instruct/          92 GB，20 分片（现: luql:~/models/ 有同一份）
│   └── MiMo-V2.6-Distill-Qwen-9B/             18 GB（现: luql:~/models/ 有同一份）
├── images/
│   └── mimo-sglang-bw10000_1.1.1.tar          31 GB（该目录实测为空；现: luql:~/work/imgstore/*.tar.gz）
├── work/
│   ├── kimi/           Kimi 件的 env.log / smoke.log / server.log / bench/
│   ├── opt/            MiMo SGLang 优化后的全量基准
│   ├── vopt/           MiMo vLLM 优化后的全量基准
│   ├── sweep/          MiMo SGLang 参数扫描（5 变体）
│   ├── vsweep2/        MiMo vLLM 参数扫描（3 变体）
│   ├── ksweep/         Kimi CUDA Graph 扫描（未完成）
│   └── clone-test/     从光合仓库匿名 clone 复现测试
└── probe/              最早的裸机探测日志
```

## 迁移现状（2026-11-25 更新）

- ✅ **有效产物已随本仓库进入 Git**（`models/*/logs/`、`models/*/bench/`）
- ✅ **镜像全部在 luql 名下**：`/public/home/luql/work/imgstore/`（4 个文件，约 60 GiB）
- ✅ **依赖 wheel / 源码在 luql 名下**：`~/wheels/`（auk-fix / fa310 / qi2 / trident / omni-fix / wan-fix）、`~/src/`（AuK-src / Wan2.1-src）
- ✅ **权重在 luql 名下**：`~/models/`（15 个被引用的模型，2026-11-25 迁入）
- ✅ **零引用孤儿已清理**：2026-11-25 删掉 502 GB（DeepSeek-V4.1-Flash 476G / Qwen2.5-7B 15G / vjepa2 11G）
- ⬜ `AuK-Flash` 主权重两账号均无（确认丢失），条目暂不可重跑，恢复方法见其 `env.sh`
- ⬜ 若要整体归档到永久账号：需先恢复该集群的 SSH 密钥
  （实测 `luql@zzeshell.scnet.cn` 报 `Permission denied (publickey)`）

## 价值排序（本项目的第一原则）

**镜像与经验 > 比赛提交。**

比赛提交是一次性的；而“哪些参数能开、哪个版本能装、哪个坑会导致假数据”的经验，
和“上游随时可能删掉的那个镜像”，是下次遇到同类国产卡时真正的起点。因此：

| 资产 | 去哪 | 频次 |
| --- | --- | --- |
| 踩坑/配方/环境实测 | `docs/gotchas.md`、`docs/environment.md`、本文件 | 每次会话结束前 |
| 启动脚本与 slurm 模板 | `models/*/container/`、`tools/` | 同上 |
| 基准/评测原始日志 | `models/*/logs/`、`models/*/bench/` | 同上 |
| **镜像 tar.gz + wheel 集** | `/public/home/luql/archive/zoo-dcu-2026-11/`（luql 账户，唯一副本；仍待推自有 Harbor 命名空间） | 新镜像用一次就归档 |
| 比赛反馈表/截图 | 各条目的 `official-eval/`、`platform/` | 有余力再补 |

**不要为了刷分重复消耗卡时**；卡时优先买“新知识”（新模型/新框架/新踩坑）和“可复现性”（归档/还原验证）。

## 重建成本

| 资产 | 重建方式 | 耗时 |
| --- | --- | --- |
| Kimi 权重 92 GB | `modelscope download --model moonshotai/Kimi-Linear-48B-A3B-Instruct` | 18 min |
| MiMo 权重 18 GB | 同上（XiaomiMiMo/MiMo-V2.6-Distill-Qwen-9B） | 3 min |
| SGLang 镜像 | `podman pull --tls-verify=false image.ac.com:5000/dcu/linshp/base/mimo-sglang-bw10000:1.1.1` | 4–6 min |
| vLLM 镜像 | 同上（`vllm0.20-...-_bw:1.0.0`） | 4–6 min |

结论：**权重与镜像不值得备份**，脚本 + 日志 + 基准数据才是需要持久化的部分，已全部入库。
