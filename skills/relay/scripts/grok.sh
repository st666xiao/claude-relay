#!/bin/zsh
# 用 Cursor CLI 调 Grok 跑一个任务（非交互）。网络偶尔 TLS 断连：刚开始就断（<60 秒）自动重试；
# 跑了很久才断的不重跑（活可能已经做完，只是回传断了），退出码 3，先看工作目录和 REPORT。
#
# 用法:
#   grok.sh [-m 模型] [-r 只读] [-w 工作目录] [-o 输出文件] "提示词"
#   -m  默认 grok-4.7-high。别用 -fast 版（计费贵很多），简单小问题可用 grok-4.7-medium
#   -r  只读（--mode ask），不改文件不跑命令
#   -w  工作目录，默认当前目录。Grok 只该碰这个目录
#   -o  把最终回答（json 的 result 字段）另存一份
# 输出: stdout 打最终回答；stderr 打耗时和 token。退出码: 0 成功；1 失败；2 用法错；3 长任务后断连，结果未知。

model=grok-4.7-high; ro=0; ws=$PWD; out=""
while getopts "m:rw:o:" opt; do
  case $opt in
    m) model=$OPTARG;; r) ro=1;; w) ws=${OPTARG:A};; o) out=$OPTARG;;
    *) echo "用法见脚本头" >&2; exit 2;;
  esac
done
shift $((OPTIND-1))
prompt="$*"
[[ -z $prompt ]] && { echo "缺提示词" >&2; exit 2; }

args=(-p --trust --model $model --workspace $ws --output-format json)
if (( ro )); then args+=(--mode ask); else args+=(--force); fi

tmp=$(mktemp -t grok); err=$(mktemp -t grokerr)
trap 'rm -f $tmp $err' EXIT
for i in 1 2 3 4 5; do
  t0=$SECONDS
  (cd $ws && cursor-agent $args "$prompt") >$tmp 2>$err && break
  if grep -qE "TLS|socket|ECONNRESET|Cannot use this model: .*Available models: *$" $err; then
    if (( SECONDS - t0 >= 60 )); then
      echo "[grok.sh] 跑了 $((SECONDS-t0)) 秒后断连。活可能已经做完，不自动重跑：先看 $ws 里的产物和 REPORT；没做完再手动重派或用 --resume。" >&2
      exit 3
    fi
    echo "[grok.sh] 网络断了，第 $i 次重试…" >&2; sleep $((i*4)); continue
  fi
  cat $err >&2; exit 1
done
[[ -s $tmp ]] || { cat $err >&2; exit 1; }

python3 -I - "$tmp" "$out" <<'EOF'
import json, sys
d = json.load(open(sys.argv[1]))
print(d.get("result", ""))
if sys.argv[2]:
    open(sys.argv[2], "w").write(d.get("result", ""))
u = d.get("usage", {})
print(f"[grok.sh] {d.get('duration_ms',0)/1000:.0f}s in={u.get('inputTokens')} out={u.get('outputTokens')} cache={u.get('cacheReadTokens')} session={d.get('session_id')}", file=sys.stderr)
sys.exit(1 if d.get("is_error") else 0)
EOF
