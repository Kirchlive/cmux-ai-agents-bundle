# Browser automation (WKWebView)

Browser surfaces are WKWebViews, not Chromium. The workflow is open → wait →
snapshot → act → re-snapshot; the snapshot returns interactive elements as
`e1`, `e2`, … which the action verbs take as targets.

```bash
S=$(cmux --json browser open https://example.com | jq -r .result.surface_ref)
cmux browser "$S" wait --load-state complete --timeout-ms 15000
cmux browser "$S" snapshot --interactive                     # elements as e1, e2, ...
cmux browser "$S" fill e1 "jane@example.com"
cmux browser "$S" click e2 --snapshot-after

# Navigation / inspection
cmux browser "$S" goto URL | back | forward | reload
cmux browser "$S" get url | get title | get text body | get value "#email" | get count ".row"
cmux browser "$S" eval 'return document.title'

# Waits
cmux browser "$S" wait --selector "#ready" --timeout-ms 10000
cmux browser "$S" wait --url-contains "/dashboard" --timeout-ms 10000

# Session state
cmux browser "$S" cookies get | cookies set --name foo --value bar
cmux browser "$S" state save /tmp/auth.json | state load /tmp/auth.json

# Diagnostics
cmux browser "$S" console list | errors list | screenshot
```

Opening a browser pane beside the current one:

```bash
cmux new-pane --workspace "$CMUX_WORKSPACE_ID" --type browser --direction right --url http://localhost:3000 --focus false
```

**Not supported by WKWebView** (these return `not_supported`): viewport
emulation, geolocation and offline emulation, trace recording, network route
interception, raw input injection. Do not expect Playwright-style network
mocking; if a test needs it, it belongs in a real browser, not here.

Re-snapshot after every action that can change the DOM — element ids are
only valid for the snapshot that produced them.
