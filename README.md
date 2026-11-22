# pi-test —— 本项目本机工作区

> ✅ **项目已结项（2026-11-09）**。本机只保留源码与仓库；**所有二进制产物、镜像、调优数据已归档到**
> `luql:/public/home/luql/archive/zoo-dcu-2026-11/`（31 GB，sha256 全核对），本机不再留副本。
> 结项报告：`zoo/docs/REPORT.md`；归档与还原：`zoo/docs/ARCHIVE-SUMMARY.md`。

国产 DCU（BW1000 / K100-AI）模型适配项目在本机的**唯一**存放处。
`~/Downloads/` 顶层不再散放任何与本项目相关的文件。

```
pi-test/
├── zoo/                 ★ 主仓库（仅 GitHub lql341；GitLab 远端 2026-11-21 已移除）
│   ├── models/          13 个条目（模型 × 卡型 × 框架）
│   ├── docs/            踩坑清单 / 环境实测 / 镜像归档 / 复现手册
│   ├── official/        官方 T03/T04 条件清单与来源记录
│   ├── sweeps/          调优过程 slurm（2026-10-11-probes/）
│   └── tools/           lint / gen_index / quota / publish / preflight
├── sources/             上游源码 clone（集群连不上 GitHub 时从这里上传）
│   ├── AuK-src/
│   ├── Wan2.1-src/
│   └── OmniWeaving-src/
├── slurm-archive/       早期 48 个实验 slurm + RECIPE.md + 竞品盘点（原件）
├── scripts/             本机侧工具（Notebook 驱动、批量下载 slurm）
├── assets/              官方原始材料包（T03/T04 99 MB）
├── {bw-vllm,kimi,mimo}-repo/  早期按条目拆的仓库快照（只读，勿再写）
├── k100ai-repo-artifacts/     K100-AI Notebook 侧产物
└── out/                 早期单脚本输出
```

## 常用入口

```bash
cd ~/Downloads/pi-test/zoo
./tools/publish.sh "提交信息"      # lint + gen_index + quota + 推 GitHub
open HANDOFF.md                    # 会话交接与 living TODO（先读这个）
```

## 集群侧对应位置

| 内容 | 位置 |
| --- | --- |
| Slurm 账户 | `scnethr2601a10`（唯一能进 `hx1hdnormal` 的账号） |
| SSH | `ssh zzeshell-hz1` |
| 镜像归档 | `~/zoo-images/`（2 个 tar.gz + `assets/` 依赖包 + `MANIFEST.md`） |
| 权重 | `~/models/`（可重下，不归档） |
| 作业工作区 | `~/work/zoo-*` |

## 不要做

- 不要把产物/镜像等二进制放进本机（已在 `luql` 归档；本机只留代码与文档）
- 不要在 `~/Downloads/` 顶层新建与本项目有关的文件/目录
- 代码只推 GitHub，不再维护 GitLab/sourcefind 远端（2026-11-21 决定）
- 不要提交模型权重、镜像 tar、`outputs/`（`.gitignore` + `check_quota.sh` 兜底）
