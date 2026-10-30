#!/bin/zsh
# 用 Codex CLI 跑一个任务（非交互）。和 grok.sh 对称。
#
# 用法:
#   codex.sh [-m 模型] [-r 只读] [-w 工作目录] [-o 输出文件] [-a 额外可写目录] "提示词"
#   -m  默认用 ~/.codex/config.toml 里的模型；要固定就传，例如 gpt-6.1-terra / gpt-6.1-sol
#   -r  只读（-s read-only），不改文件
#   -w  工作目录，默认当前目录。写模式用 -s workspace-write，只能写这个目录（和 -a）
#   -o  把最终回答另存一份（默认 <工作目录>/.codex-last.txt）
#   -a  额外可写目录，可重复
# 输出: stdout 打最终回答；stderr 打耗时和日志位置。退出码非 0 = 失败。
# 不自动重试：Codex 失败多半是额度、登录或沙箱，重跑没用，交给 Opus 判断。

bin=$(command -v codex)
[[ -z $bin ]] && bin="/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex"
[[ -x $bin ]] || { echo "[codex.sh] 找不到 codex 可执行文件（ChatGPT.app 更新后路径可能变了）" >&2; exit 2; }

model=""; ro=0; ws=$PWD; out=""; adds=()
while getopts "m:rw:o:a:" opt; do
  case $opt in
    m) model=$OPTARG;; r) ro=1;; w) ws=${OPTARG:A};; o) out=$OPTARG;; a) adds+=(--add-dir ${OPTARG:A});;
    *) echo "用法见脚本头" >&2; exit 2;;
  esac
done
shift $((OPTIND-1))
prompt="$*"
[[ -z $prompt ]] && { echo "缺提示词" >&2; exit 2; }
[[ -z $out ]] && out=$ws/.codex-last.txt
log=$ws/.codex-run.log

args=(exec --skip-git-repo-check -C $ws -o $out)
[[ -n $model ]] && args+=(-m $model)
if (( ro )); then args+=(-s read-only); else args+=(-s workspace-write $adds); fi

start=$SECONDS
print -r -- "$prompt" | "$bin" "${args[@]}" - >"$log" 2>&1
rc=$?
echo "[codex.sh] $((SECONDS-start))s exit=$rc log=$log" >&2
[[ -s $out ]] && { cat $out; echo; }
if (( rc != 0 )); then
  tail -20 $log >&2
  grep -qiE "usage limit|rate limit|quota|429" $log && echo "[codex.sh] 像是额度用完了，按 SKILL.md「换执行者」处理" >&2
fi
exit $rc
