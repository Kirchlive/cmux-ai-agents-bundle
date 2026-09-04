#!/usr/bin/env bash
# wait-idle.sh — block until an agent session driven in cmux has finished its turn.
# Works for every agent cmux has hooks for (claude, codex, kimi, gemini, opencode,
# antigravity, grok, pi, amp, cursor, copilot, ...), because cmux keeps one
# lifecycle record per session in ~/.cmuxterm/<agent>-hook-sessions.json and
# exposes it through `cmux sessions --json` — no socket required.
#
#   scripts/wait-idle.sh --agent <name> (--session <id-prefix> | --cwd <path> | --pid <pid>)
#                        [--fresh] [--timeout <s>] [--poll <s>] [--surface surface:N]
#
#   --agent    cmux agent name: claude codex kimi gemini opencode antigravity grok pi omp
#              campfire amp cursor kiro rovodev copilot codebuddy factory qoder hermes-agent
#   --session  session id or a prefix of it (the agent's own id, as shown in its footer)
#   --cwd      pick the newest record whose cwd matches instead
#   --pid      pick the record with this agent pid
#   --fresh    only accept an idle state recorded AFTER this script started — use it
#              right after sending a prompt, so a stale "idle" from before the prompt
#              does not count
#   --surface  screen-hash fallback target if no record exists (needs the cmux socket)
#
# Exit codes: 0 idle   3 needs input   2 timeout   4 no record and no --surface
#
# The output is written to be read as a notification: run this in the background and
# the completion line tells you what to do next (review the surface, answer the
# prompt, or wait again). When it arrives while you are mid-task, it is a queued
# task, not information — finish the step you are on, then do the review.
#
# Lifecycle values cmux writes: running | idle | needsInput | unknown. Every hooked
# agent maps its own events onto the same three cmux subcommands (prompt-submit ->
# running, stop -> idle, notification -> needsInput), which is why one script fits all.
#
# Why not a "screen stopped changing" loop: the footer counters tick every minute,
# so a 40 s stability window keeps being reset and the wait takes minutes for a
# turn that ended seconds ago. This reacts within one poll interval.
set -u
AGENT=""; SESSION=""; CWD=""; PID=""; FRESH=0; TIMEOUT=600; POLL=2; SURFACE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --agent)   AGENT="$2"; shift 2;;
    --session) SESSION="$2"; shift 2;;
    --cwd)     CWD="$2"; shift 2;;
    --pid)     PID="$2"; shift 2;;
    --fresh)   FRESH=1; shift;;
    --timeout) TIMEOUT="$2"; shift 2;;
    --poll)    POLL="$2"; shift 2;;
    --surface) SURFACE="$2"; shift 2;;
    -h|--help) sed -n '2,30p' "$0"; exit 0;;
    *) echo "unknown option: $1" >&2; exit 64;;
  esac
done
[ -n "$SESSION$CWD$PID$SURFACE" ] || { echo "need --session, --cwd, --pid or --surface" >&2; exit 64; }

CMUX_BIN=$(command -v cmux || echo /Applications/cmux.app/Contents/Resources/bin/cmux)
STATE_DIR="${CMUX_AGENT_HOOK_STATE_DIR:-$HOME/.cmuxterm}"
START=$(date +%s)
export CMUX_QUIET=1

# One JSON record for the target session, or nothing. Tries `cmux sessions` first
# (present on 0.64.22 even though --help does not list it), then the store file.
lookup() {
  python3 - "$CMUX_BIN" "$STATE_DIR" "$AGENT" "$SESSION" "$CWD" "$PID" <<'PY'
import json, os, subprocess, sys, glob
cmux, state_dir, agent, sid, cwd, pid = sys.argv[1:7]
recs = []
args = [cmux, "sessions", "--json", "--all"] + (["--agent", agent] if agent else [])
try:
    out = subprocess.run(args, capture_output=True, text=True, timeout=10).stdout
    d = json.loads(out)
    for r in d.get("sessions", []):
        recs.append({"agent": r.get("agent"), "session_id": r.get("session_id"),
                     "cwd": r.get("cwd"), "pid": r.get("pid"), "surface": r.get("surface_id") or "",
                     "lifecycle": r.get("agent_lifecycle") or "unknown",
                     "updated": r.get("updated_at_unix") or 0})
except Exception:
    pattern = os.path.join(state_dir, f"{agent or '*'}-hook-sessions.json")
    for f in glob.glob(pattern):
        try: store = json.load(open(f))
        except Exception: continue
        name = os.path.basename(f).replace("-hook-sessions.json", "")
        for k, v in (store.get("sessions") or {}).items():
            recs.append({"agent": name, "session_id": v.get("sessionId", k), "cwd": v.get("cwd"),
                         "pid": v.get("pid"), "surface": v.get("surfaceId") or "",
                         "lifecycle": v.get("agentLifecycle") or "unknown",
                         "updated": v.get("updatedAt") or 0})
def ok(r):
    if sid and not str(r["session_id"]).lower().startswith(sid.lower()): return False
    if cwd and os.path.normpath(str(r["cwd"] or "")) != os.path.normpath(cwd): return False
    if pid and str(r["pid"]) != str(pid): return False
    return True
hits = sorted([r for r in recs if ok(r)], key=lambda r: r["updated"], reverse=True)
if hits:
    r = hits[0]
    print(f'{r["lifecycle"]} {int(r["updated"])} {r["agent"]} {r["session_id"]} {r["pid"]} {r["surface"] or "-"}')
PY
}

screen_hash() {
  "$CMUX_BIN" read-screen --surface "$SURFACE" --lines 25 2>/dev/null \
    | grep -vE '[0-9]+h: [0-9]+%|tokens ·|Tip: |^[[:space:]]*$' | { md5 2>/dev/null || md5sum; } | cut -c1-32
}

first=$(lookup)
if [ -z "$first" ] && [ -z "$SURFACE" ]; then
  echo "no session record under $STATE_DIR matching agent='$AGENT' session='$SESSION' cwd='$CWD' pid='$PID', and no --surface fallback" >&2
  exit 4
fi

prev=""; stable=0
while :; do
  now=$(date +%s); [ $((now-START)) -ge "$TIMEOUT" ] && { echo "WAIT-IDLE: TIMEOUT after ${TIMEOUT}s — still running. NEXT: check the surface, then start another wait."; exit 2; }
  rec=$(lookup)
  if [ -n "$rec" ]; then
    read -r life updated agent sid pid surf <<<"$rec"
    target=${SURFACE:-$surf}; [ "$target" = "-" ] && target="<surface>"
    case "$life" in
      needsInput)
        echo "WAIT-IDLE: NEEDS INPUT — $agent session $sid (pid $pid) is blocked on a permission prompt or question."
        echo "NEXT: cmux read-screen --surface $target --lines 40   # answer it before anything else"
        exit 3;;
      idle)
        if [ "$FRESH" -eq 0 ] || [ "$updated" -ge "$START" ]; then
          echo "WAIT-IDLE: DONE — $agent session $sid (pid $pid) finished its turn."
          echo "NEXT: review it before you send anything: cmux read-screen --surface $target --lines 60, then check the artefacts (git log, tests). If you are mid-task, queue this review as your next step — do not let it drop."
          exit 0
        fi;;
    esac
  elif [ -n "$SURFACE" ]; then
    cur=$(screen_hash)
    if [ "$cur" = "$prev" ]; then stable=$((stable+1)); else stable=0; prev=$cur; fi
    [ $stable -ge 3 ] && { echo "WAIT-IDLE: DONE — screen of $SURFACE stable (no lifecycle record; may also be a prompt). NEXT: cmux read-screen --surface $SURFACE --lines 60 and review."; exit 0; }
  fi
  sleep "$POLL"
done
