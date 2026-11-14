#!/usr/bin/env bash
# Read-only pre-edit gate. Prints a workspace verdict and does not write git state.
#
# Usage:
#   verify-workspace.sh --workspace PATH --branch NAME --base REF \
#     [--require-cwd PATH] [--t3-status PATH] [--settings PATH]
set -u

workspace_arg=""
branch_arg=""
base_arg=""
require_cwd=""
t3_status=""
settings_arg=""
seen_workspace=0
seen_branch=0
seen_base=0
bad_args=0

while [ $# -gt 0 ]; do
  case "$1" in
    --workspace|--branch|--base|--require-cwd|--t3-status|--settings)
      if [ $# -lt 2 ]; then
        bad_args=1
        break
      fi
      case "$1" in
        --workspace) workspace_arg=$2; seen_workspace=1 ;;
        --branch) branch_arg=$2; seen_branch=1 ;;
        --base) base_arg=$2; seen_base=1 ;;
        --require-cwd) require_cwd=$2 ;;
        --t3-status) t3_status=$2 ;;
        --settings) settings_arg=$2 ;;
      esac
      shift 2
      ;;
    *)
      bad_args=1
      shift
      ;;
  esac
done

rp() {
  realpath "$1" 2>/dev/null
}

git_ro() {
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE git "$@"
}

workspace_out="-"
branch_out="-"
base_out="missing"
t3_out="unverified"
hook_out="unverified"
reason="ok"
toplevel=""
git_ok=0

fail() {
  if [ "$reason" = "ok" ]; then
    reason=$1
  fi
}

if [ "$bad_args" -ne 0 ] || [ "$seen_workspace" -ne 1 ] || [ "$seen_branch" -ne 1 ] || [ "$seen_base" -ne 1 ]; then
  fail bad-args
fi

if [ -n "$workspace_arg" ]; then
  ws_rp=$(rp "$workspace_arg" || true)
  if [ -n "${ws_rp:-}" ]; then
    workspace_out=$ws_rp
  else
    fail workspace-missing
  fi
  tl=$(git_ro -C "$workspace_arg" rev-parse --show-toplevel 2>/dev/null || true)
  tl_rp=""
  if [ -n "${tl:-}" ]; then
    tl_rp=$(rp "$tl" || true)
  fi
  if [ -n "${ws_rp:-}" ] && [ -n "${tl_rp:-}" ] && [ "$ws_rp" = "$tl_rp" ]; then
    toplevel=$tl_rp
    git_ok=1
  elif [ -n "${ws_rp:-}" ]; then
    fail workspace-mismatch
  fi
else
  fail workspace-missing
fi

if [ "$git_ok" -eq 1 ]; then
  actual=$(git_ro -C "$workspace_arg" branch --show-current 2>/dev/null || true)
  if [ -n "${actual:-}" ]; then
    branch_out=$actual
  fi
  if [ "$branch_out" != "$branch_arg" ]; then
    fail branch-mismatch
  fi

  found=0
  while IFS= read -r line; do
    case "$line" in
      worktree\ *)
        wt_path=${line#worktree }
        wt_rp=$(rp "$wt_path" || true)
        if [ -n "${wt_rp:-}" ] && [ "$wt_rp" = "$toplevel" ]; then
          found=1
        fi
        ;;
    esac
  done <<EOF
$(git_ro -C "$workspace_arg" worktree list --porcelain 2>/dev/null || true)
EOF
  if [ "$found" -ne 1 ]; then
    fail worktree-missing
  fi

  if git_ro -C "$workspace_arg" rev-parse --verify --quiet "${base_arg}^{commit}" >/dev/null 2>&1; then
    if git_ro -C "$workspace_arg" merge-base --is-ancestor "$base_arg" HEAD >/dev/null 2>&1; then
      base_out="ok"
    else
      base_out="mismatch"
      fail base-mismatch
    fi
  else
    base_out="missing"
    fail base-missing
  fi
else
  fail branch-mismatch
  base_out="missing"
  fail base-missing
fi

if [ -n "$require_cwd" ]; then
  pwd_rp=$(rp "$(pwd)" || true)
  req_rp=$(rp "$require_cwd" || true)
  if [ -z "${pwd_rp:-}" ] || [ -z "${req_rp:-}" ] || [ "$pwd_rp" != "$req_rp" ]; then
    fail cwd-mismatch
  fi
fi

if [ -z "$t3_status" ] || [ ! -r "$t3_status" ]; then
  t3_out="unverified"
  fail t3-unverified
else
  t3_raw=$(python3 - "$t3_status" <<'PY'
import json, sys
path = sys.argv[1]
try:
    with open(path) as fh:
        data = json.load(fh)
except Exception:
    print("unverified")
    raise SystemExit(0)
if not isinstance(data, dict) or data.get("attached") is not True:
    print("unverified")
    raise SystemExit(0)
wp = data.get("worktreePath")
br = data.get("branch")
if not isinstance(wp, str) or wp == "" or not isinstance(br, str) or br == "":
    print("unverified")
    raise SystemExit(0)
print("fields")
print(wp)
print(br)
PY
)
  kind=""
  wp=""
  br=""
  {
    IFS= read -r kind || true
    IFS= read -r wp || true
    IFS= read -r br || true
  } <<EOF
$t3_raw
EOF
  if [ "$kind" = "fields" ]; then
    wp_rp=$(rp "$wp" || true)
    if [ -n "${wp_rp:-}" ] && [ -n "$toplevel" ] && [ "$wp_rp" = "$toplevel" ] && [ "$br" = "$branch_arg" ]; then
      t3_out="match"
    else
      t3_out="mismatch"
      fail t3-mismatch
    fi
  else
    t3_out="unverified"
    fail t3-unverified
  fi
fi

hook_file=""
if [ -n "$settings_arg" ]; then
  hook_file=$settings_arg
elif [ -n "${CLAUDE_CONFIG_DIR:-}" ] && [ -r "${CLAUDE_CONFIG_DIR}/settings.json" ]; then
  hook_file=$CLAUDE_CONFIG_DIR/settings.json
elif [ -r "${HOME}/.claude/settings.json" ]; then
  hook_file=${HOME}/.claude/settings.json
elif [ "$workspace_out" != "-" ] && [ -r "${workspace_out}/.claude/settings.json" ]; then
  hook_file=${workspace_out}/.claude/settings.json
fi

if [ -z "$hook_file" ] || [ ! -r "$hook_file" ]; then
  hook_out="unverified"
else
  hook_out=$(python3 - "$hook_file" <<'PY'
import json, sys
path = sys.argv[1]
try:
    with open(path) as fh:
        data = json.load(fh)
except Exception:
    print("unverified")
    raise SystemExit(0)
if not isinstance(data, dict):
    print("unverified")
    raise SystemExit(0)
hooks = data.get("hooks")
if hooks is None:
    print("not-installed")
    raise SystemExit(0)
found = False

def walk(node):
    global found
    if isinstance(node, dict):
        for key, value in node.items():
            if key == "command" and isinstance(value, str) and "guard.sh" in value:
                found = True
            else:
                walk(value)
    elif isinstance(node, list):
        for value in node:
            walk(value)

walk(hooks)
print("installed" if found else "not-installed")
PY
)
  case "$hook_out" in
    installed|not-installed|unverified) ;;
    *) hook_out="unverified" ;;
  esac
fi

if [ "$reason" = "ok" ]; then
  result="pass"
  exit_code=0
else
  result="fail"
  exit_code=1
fi

printf 'workspace=%s\n' "$workspace_out"
printf 'branch=%s\n' "$branch_out"
printf 'base=%s\n' "$base_out"
printf 't3_binding=%s\n' "$t3_out"
printf 'hook=%s\n' "$hook_out"
printf 'result=%s\n' "$result"
printf 'reason=%s\n' "$reason"
exit "$exit_code"
