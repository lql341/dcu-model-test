# dcu-model-test —— 国产 DCU 模型适配工作区（总仓）

> 国产 DCU（BW1000 / K100-AI）模型适配项目的**唯一存放处**。
> 2026-11-09 结项，定位是**能力沉淀，不是比赛提交**：所有产出的第一价值是"下一个人能复用"。

本仓由原 `scnet-dcu-model-zoo` 并入而来（2026-11-22，`git subtree` 保留全部 119 次提交历史）。
原仓库 `lql341/scnet-dcu-model-zoo` 已归档且只读，内容全部包含在本仓 `zoo/` 下。

## 许可

[Apache License 2.0](LICENSE)，Copyright 2026 lql341。

覆盖本仓自有的脚本、文档、配置与 patch。**不含**下列内容：

| 内容 | 说明 |
| --- | --- |
| `sources/`（未入库） | 上游模型源码，各自许可证见对应上游仓库（AuK / Wan2.1 / HY-World-2.0 / MiniMax-Music3 / OmniWeaving） |
| 模型权重 | 从 ModelScope 下载，受各自模型许可约束，本仓不分发 |
| 容器镜像 | 3 个来自第三方账号（`dcu/linshp`、`dcu/wqxyyt06`、`dcu/acizv7iztz`），非本项目构建 |
| `assets/`（未入库） | 赛事官方材料，版权归发布方 |

各条目若有第三方组件，会在该条目目录下用 `THIRD-PARTY.md` 记录来源与许可
（目前 `OpenBMB__Trident-Qwen3VL-2B__bw1000__transformers/` 有一份：内嵌官方推理封装，MIT）。

## 目录

```
dcu-model-test/
├── zoo/                  ★ 主内容：21 条目 / 63 踩坑 / 9 个 6 档基准 / 935 条官方产物
│   ├── models/           21 个条目（模型 × 卡型 × 框架 × 精度）
│   ├── docs/             gotchas 63 条、环境实测、镜像归档、复现手册
│   ├── official/         官方 T03/T04 条件清单（素材不入库，按 manifest 重领）
│   ├── sweeps/           调优过程 slurm 与结果记录
│   ├── tools/            lint / gen_index / quota / publish / preflight
│   ├── HANDOFF.md        ★ 交接文档与 living TODO（先读这个）
│   └── INDEX.md          实测索引（由 meta.json 生成，勿手改）
├── sources/              上游源码 clone（5 个，各自有远端，不入本仓）
├── assets/               官方原始材料包（92 MB zip，超 GitHub 单文件限，不入本仓）
├── k100ai-repo-artifacts/ K100-AI 卡唯一一手运行记录（本地保留，不入本仓）
├── scripts/              本机侧工具（Notebook 驱动、sourcefind 推送）
└── slurm-archive/        早期 48 个实验 slurm + RECIPE + 竞品盘点
```

## 常用入口

```bash
cd zoo
./tools/publish.sh "提交信息"      # lint + gen_index + quota + commit + push
open HANDOFF.md                    # 交接文档（先读这个）
python3 tools/gen_report.py        # 重生成统计段
```

## 不入库的东西（见 `.gitignore`）

| 目录 | 为什么不入库 |
| --- | --- |
| `sources/` | 上游源码 clone（883 MB），各自有远端，重复存储无意义 |
| `assets/` | 官方材料 zip 单文件 92 MB，超 GitHub 100 MB 硬限 |
| `k100ai-repo-artifacts/` | 一手运行日志，与 zoo 条目体裁不同；本地保留即可 |

## 集群通道（2026-11-22 起）

⚠️ **SSH 与集群外网都已失效**，作业提交与文件收发一律走 OpenAPI：

```bash
S=~/Downloads/agent/skills/scnet-hpc/scripts/scnet.py
python3 $S --region 20091 submit --name <名> --queue hx1hdnormal \
  --nodes 1 --dcus 1 --cpus 16 --memory 32GB --walltime 02:00:00 \
  --work-dir /public/home/luql/work/<目录> --command "$(cat job.sh)"
```

详见 `zoo/HANDOFF.md` §7「OpenAPI 通道」，以及 `zoo/docs/gotchas.md` #60–#63。

## 不要做

- 不要在 `sources/*` 里本地改后回推（origin 指向上游）
- 不要提交模型权重、镜像 tar、`outputs/`（`.gitignore` + `check_quota.sh` 兜底）
- 不要把二进制产物放进本机（已归档到集群，见 `zoo/docs/ARCHIVE-SUMMARY.md`）