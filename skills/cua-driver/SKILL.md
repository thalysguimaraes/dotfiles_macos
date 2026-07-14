---
name: cua-driver
description: Drive macOS desktop apps in the background with Cua Driver — the computer-use alternative for pi (no MCP needed). Launch apps, read accessibility trees, click/type/scroll by element_index or pixel, capture screenshots, and automate browsers/Electron apps without stealing keyboard focus or moving the user's cursor. Use when asked to operate, drive, automate, or read a native desktop app, do "computer use", or interact with GUI apps that aren't inside the Orca app itself.
---

# Cua Driver on pi (computer use via one-shot CLI)

Pi does not support MCP. Drive Cua Driver as a plain CLI instead — every MCP
tool is callable as a one-shot shell command that prints JSON to stdout:

```bash
cua-driver <tool_name> '<JSON-args>'      # e.g. cua-driver list_apps
```

Binary: `~/.local/bin/cua-driver` (on PATH). If `cua-driver` is not found,
use the absolute path `$HOME/.local/bin/cua-driver`.

**Full reference docs** (read when you need depth — this file is the pi quickstart):

- `~/.cua-driver/skills/cua-driver/SKILL.md` — cross-platform core: full tool surface, behavior matrix, failure modes
- `~/.cua-driver/skills/cua-driver/MACOS.md` — no-foreground contract, forbidden commands, menu-bar navigation
- `~/.cua-driver/skills/cua-driver/WEB_APPS.md` — browsers, Electron, Tauri, the `page` tool
- `~/.cua-driver/skills/cua-driver/RECORDING.md` — trajectory recording/replay

The same pack is also linked at `~/.agents/skills/cua-driver/` (skill name
`cua-driver-rs`). Treat this file as the entry point on pi.

## Prerequisites / troubleshooting

The driver proxies calls through a daemon that holds the TCC grants
(Accessibility + Screen Recording). If a call fails with a socket,
permission, or "daemon not running" error:

```bash
open -n -g -a CuaDriver --args serve   # start daemon (background, no focus steal)
cua-driver permissions status           # both must be ✅ granted
cua-driver doctor                       # full environment probe
```

If permissions show ❌/❓, run `cua-driver permissions grant` and tell the
user to approve CuaDriver in System Settings → Privacy & Security.

## The no-foreground contract

The user's frontmost app MUST NOT change and their cursor MUST NOT move.
Never drive GUI apps with `open <app>`, `osascript` that mutates GUI state,
or `cliclick` — always use the cua-driver tool with the same intent.
`launch_app` and all input tools run backgrounded by default.

## Canonical loop

```bash
# 1. Find or launch the target (backgrounded; returns pid + windows)
cua-driver launch_app '{"bundle_id":"com.apple.calculator"}'
cua-driver list_apps                          # is X running/installed?
cua-driver list_windows '{"pid":33554}'       # find window_id

# 2. Snapshot: AX tree + screenshot in one call
cua-driver get_window_state '{"pid":33554,"window_id":4573,"screenshot_out_file":"/tmp/win.png"}'
#   → elements[] with element_index, role, label, value, frame
#   Read /tmp/win.png with the read tool when you need pixels.
#   Tree-only (cheap, no image): add "include_screenshot":false
#   Huge Electron trees: add "max_elements":400 and/or "query":"substring"

# 3. Act by element_index (preferred — works on backgrounded/hidden windows)
cua-driver click '{"pid":33554,"window_id":4573,"element_index":12}'
cua-driver type_text '{"pid":33554,"text":"hello"}'
cua-driver press_key '{"pid":33554,"key":"return"}'
cua-driver hotkey '{"pid":33554,"keys":["cmd","s"]}'
cua-driver set_value '{"pid":33554,"window_id":4573,"element_index":7,"value":"42"}'
cua-driver scroll '{"pid":33554,"direction":"down","amount":3}'

# 4. Verify: re-snapshot and check the effect landed
cua-driver get_window_state '{"pid":33554,"window_id":4573,"include_screenshot":false}'
```

**Snapshot invariant (not optional):** `element_index` values are scoped to
the last `get_window_state` of that (pid, window_id) and are replaced by the
next snapshot. Re-snapshot before every element-indexed action.
`element_index` always requires `pid` AND `window_id` alongside it.

## Escalation ladder

Act on the response's `effect` + `escalation.recommended` fields, in order:

1. **AX by element_index, background** (default). `effect:"confirmed"` means
   verified via read-back — done.
2. **Pixel, background** — when escalation recommends `"px"`, or the target is
   a canvas/video/custom-drawn surface absent from the AX tree. Pass `x`,`y`
   read straight off the `get_window_state` PNG (window-local, top-left
   origin, no scaling math): `cua-driver click '{"pid":P,"window_id":W,"x":320,"y":210}'`.
   Same form works on `type_text`/`press_key`/`hotkey` (pixel-clicks to focus,
   then types) — the fix for Electron/Chromium inputs that echo-confirm AX writes.
3. **`page` tool** — when escalation recommends `"page"` for browser-tab DOM:
   `cua-driver page '{"pid":P,"action":"execute_javascript","javascript":"..."}'`
   (also: `get_text`, `query_dom`, `click_element`, `insert_text`,
   `type_keystrokes`). See WEB_APPS.md.
4. **`delivery_mode:"foreground"`** — explicit last resort; briefly fronts the
   window then restores. Only for the single action that needs it.

Pixel clicks and key events are never driver-verifiable (`verified:false`) —
always confirm via re-snapshot; don't trust the success status alone.

## Quick tool map

- Inspect: `list_apps`, `list_windows`, `get_window_state`,
  `get_accessibility_tree` (fast desktop overview, no TCC),
  `get_desktop_state` (full-screen shot), `get_screen_size`
- Act: `launch_app`, `click`, `double_click`, `right_click`, `drag`,
  `type_text`, `press_key`, `hotkey`, `set_value`, `scroll`, `zoom`,
  `kill_app` (SIGKILL — prefer `hotkey cmd+q` first), `bring_to_front`
  (persistent focus steal — almost never needed)
- Browser/Electron: `page`; launch with `cdp_debugging_port` for CDP control
- Recording: `start_recording`, `stop_recording`, `replay_trajectory`
- Full catalog: `cua-driver list-tools` / `cua-driver describe <tool>`

## Multi-agent note

If another agent/session may drive the same app, launch with
`"creates_new_application_instance":true` to get an isolated pid + window
instead of clobbering a shared instance.

## When to use what

- **This skill (cua-driver):** any native desktop app, background automation,
  reading app state without focus steal — the general computer-use path.
- **orca-cli skill:** Orca-managed worktrees/terminals and the browser
  embedded inside the Orca app.
- **computer-use skill (Orca computer-use CLI):** legacy alternative for
  desktop UI; prefer cua-driver for new work — it verifies actions and never
  steals focus.
