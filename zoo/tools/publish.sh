#!/usr/bin/env bash
# 一次收尾：四件套校验 → 提交 → 推 GitHub
#
# 「四件套」= lint_entry + check_products + check_quota + gen_index（定义见 HANDOFF §7）。
# 本脚本全部会跑，所以日常只需跑这一个。
#
# 本项目第一原则是「镜像与经验 > 比赛提交」，GitHub 是权威积累库。
# 只推 origin 指向的仓库（2026-11-22 起为 lql341/dcu-model-test）。
#
# 用法：
#   tools/publish.sh "commit message"          # 四件套 + 提交 + 推 GitHub
#   tools/publish.sh "msg" --no-push           # 只校验 + 提交
#   tools/publish.sh "" --check                # 只跑四件套校验，不提交
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
MSG="${1:-}"
MODE="${2:-}"

fail() { echo "[publish] ✗ $*" >&2; exit 1; }

echo "== 1/5 规范校验 =="
./tools/lint_entry.sh >/tmp/lint.out 2>&1 || { tail -20 /tmp/lint.out; fail "lint 未通过"; }
tail -1 /tmp/lint.out

echo "== 2/5 产物一致性 =="
python3 tools/check_products.py >/tmp/products.out 2>&1 || { tail -20 /tmp/products.out; fail "产物与 meta 不一致"; }
tail -1 /tmp/products.out

echo "== 3/5 重生成索引 =="
python3 tools/gen_index.py || fail "gen_index 失败"

echo "== 4/5 体积守门 =="
./tools/check_quota.sh >/tmp/quota.out 2>&1 || { tail -20 /tmp/quota.out; fail "体积超限"; }
tail -1 /tmp/quota.out

[ "$MODE" = "--check" ] && { echo "[publish] 仅校验完成（工作区改动未提交）"; git status --short; exit 0; }

echo "== 5/5 提交并推 GitHub =="
# 2026-11-22 起 zoo/ 是总仓 lql341/dcu-model-test 的子目录，.git 在上一级。
# 所以只 add 本目录（zoo/），不要把总仓根目录的东西一起提交。
if [ -n "$(git status --porcelain -- .)" ]; then
  [ -n "$MSG" ] || fail "工作区有改动但没给提交信息"
  git add -A -- . && git commit -q -m "$MSG" || fail "commit 失败"
  echo "已提交：$(git log --oneline -1)"
else
  echo "工作区干净，跳过提交"
fi

[ "$MODE" = "--no-push" ] && { echo "[publish] 已跳过推送"; exit 0; }

# 推送：优先用 remote origin 的地址，不要在脚本里硬编码仓库 URL
# （旧版硬编码 scnet-dcu-model-zoo，该仓 2026-11-22 已归档只读，push 会失败）
REMOTE=$(git remote get-url origin 2>/dev/null) || {
  echo "[publish] ⚠ 没有 origin remote，跳过推送"; exit 0; }
if ! git push -q origin HEAD 2>/dev/null; then
  echo "[publish] 默认推送失败，改用 gh 凭据走 HTTPS（$REMOTE）"
  HTTPS=$(echo "$REMOTE" | sed -E 's#^git@github\.com:#https://github.com/#; s#\.git$##')
  git -c credential.helper='!gh auth git-credential' push -q "$HTTPS" HEAD:main \
    || echo "[publish] ⚠ GitHub 推送失败（检查网络 / gh auth）"
fi
echo "[publish] 完成"
