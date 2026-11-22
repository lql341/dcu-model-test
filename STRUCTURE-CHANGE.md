# 仓库结构变更记录（2026-11-22）

## 做了什么

把原来"一棵目录树里嵌 9 个独立 git 仓库"的工作区，合成**单一顶层仓库**。

```
变更前                      变更后
dcu-model-test/（无 .git）   dcu-model-test/（顶层 .git，123 次提交）
├── zoo/          →独立仓    ├── zoo/          ← 119 次历史并入，前缀改写为 zoo/
├── bw-vllm-repo/ →独立仓    ├── sources/      ← 仍不入库（各自有远端）
├── kimi-repo/    →独立仓    ├── assets/       ← 仍不入库（92 MB 超单文件限）
├── mimo-repo/    →独立仓    ├── k100ai-repo-artifacts/
├── sources/*     →5 个仓    ├── scripts/
└── assets/                   └── slurm-archive/
```

## 合并方式

用 `git filter-branch --index-filter` 给 zoo 的 119 次提交全部加上 `zoo/` 前缀，
再以 `--allow-unrelated-histories` 并入顶层仓库。

**提交 SHA 全部改变是预期行为**（路径前缀参与 tree 计算）。原仓库
`lql341/scnet-dcu-model-zoo` 保持不动，可随时对照或归档。

## 删掉的东西（4 项，5.3 MB）

| 目录 | 删除依据 |
| --- | --- |
| `mimo-repo/` | 内容全在 zoo 有对应；`failed-ctx17408` 已入库，`server.log` md5 同源 |
| `bw-vllm-repo/` | 同上，`server.log` md5 完全一致 |
| `kimi-repo/` | 唯一独有的 `round2_16384_1024_c1.log` 已归位到 zoo 的 `bench-baseline-v1/` |
| `out/` | 单个旧 slurm，已被 zoo 的正式脚本取代 |

删除前逐项核对了 `diff -rq` 与 `md5sum`，不是凭目录名判断。
`kimi-repo` 那份原始分档日志（16K/c1 = 14.01 tok/s，优化前基线）**先复制进
`zoo/models/.../bench-baseline-v1/` 再删**，并补了 README 说明用途。

## 保留但不入库

| 目录 | 原因 |
| --- | --- |
| `sources/` | 5 个上游 clone（883 MB），各自有远端，重复存储无意义 |
| `assets/` | 官方材料 zip 单文件 92 MB，超 GitHub 100 MB 硬限 |
| `k100ai-repo-artifacts/` | K100-AI 卡唯一一手运行记录（vllm 0.18.1 跑通），zoo 无对应条目 |

## 顺带修掉的一个隐患

zoo 里有 22 个 `patches/` 是**空目录**，原仓库靠"本地目录存在"通过 `lint_entry.sh`。
git 不跟踪空目录，所以任何 clone 下来都会报"缺 patches/"——这是**原有的 bug**，
只是从没人在干净 clone 里跑过 lint 才发现。本次补了 `.gitkeep`。

## 验证

```bash
git clone <本仓> /tmp/t && cd /tmp/t/zoo
./tools/lint_entry.sh        # 全部通过（21 条目）
./tools/check_quota.sh       # OK
python3 tools/check_products.py  # 21 个目录全部一致
./tools/publish.sh "" --check    # 四件套通过
```

## 回滚

合并前的完整 zoo 副本在 `/tmp/zoo_live_hold`（临时目录，重启即失）。
需要长期回滚请用原 GitHub 仓库 `lql341/scnet-dcu-model-zoo`。
