# Socket API

The CLI is a thin client over a Unix socket speaking JSON-RPC v2. Use the
socket directly only for tight loops where subprocess spawn cost matters;
otherwise the CLI is the same thing with less to get wrong.

## Path and access

The socket is `$CMUX_SOCKET_PATH`, injected into every cmux-spawned
terminal (typically `~/.local/state/cmux/cmux-<uid>.sock`). Never assume
`/tmp/cmux.sock`.

Access is governed by `socketControlMode` in the app's preferences
(Settings → Automation):

| Mode | Who may connect |
| :-- | :-- |
| `cmuxOnly` (default) | processes whose ancestry includes cmux |
| `automation` | any local process |
| `password` | anyone presenting the password (`--password`, `CMUX_SOCKET_PASSWORD`, or the saved one) |
| `allowAll` | anyone — unsafe |

Under `cmuxOnly` an external process gets `Access denied - only processes
started inside cmux can connect`. The mode is read when the app starts:
changing it with `defaults write com.cmuxterm.app socketControlMode
automation` does not take effect on the running app (measured on 0.64.22).
Restarting cmux to pick it up ends every session it hosts, so when an
external process needs to observe agents, prefer the file-based signals in
`waiting-for-an-agent.md` over changing the mode mid-flight.

## Calling it

```bash
echo '{"id":"1","method":"workspace.list","params":{}}' | nc -U "$CMUX_SOCKET_PATH"
echo '{"id":"r","method":"surface.read_text","params":{"surface_id":"surface:7","lines":40}}' | nc -U "$CMUX_SOCKET_PATH" | jq .
```

`cmux rpc <method> [json-params]` does the same from the CLI, and
`cmux capabilities --json` enumerates the methods the running build offers —
use that rather than a remembered list, since methods are added between
builds. Method prefixes: `system.*`, `window.*`, `workspace.*`, `pane.*`,
`surface.*`, `notification.*`, `browser.*`.

Legacy v1 payloads of the form `{"command": …}` are rejected; send v2
JSON-RPC only.

## Event stream

`cmux events` tails the app's event log. Useful filters:

```bash
cmux events --category agent --name agent.hook.Stop      # agent lifecycle from installed hooks
cmux events --after <seq> --cursor-file ~/.cmux-cursor   # resume where you left off
cmux events --no-heartbeat --limit 50
```

The same events are appended to `~/.cmuxterm/events.jsonl` (rotated to
`.1`), which is how an external process can read them without socket
access. Each line carries `name`, `category`, `seq`, `occurred_at` and a
`payload`; agent hook payloads include `session_id`, `_ppid`, `cwd` and the
hook event name.
