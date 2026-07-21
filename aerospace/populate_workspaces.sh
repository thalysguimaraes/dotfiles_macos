#!/usr/bin/env bash

set -euo pipefail

PATH="/opt/homebrew/bin:/opt/homebrew/sbin:${PATH}"

if ! command -v aerospace >/dev/null 2>&1; then
  exit 0
fi

current_workspace="$(aerospace list-workspaces --focused | head -n 1 | tr -d '[:space:]')"

restore_focus() {
  if [[ -n "${current_workspace:-}" ]]; then
    aerospace workspace "${current_workspace}"
  fi
}
trap restore_focus EXIT

launch_app() {
  local app_name="$1"
  if ! open -gj -a "${app_name}" >/dev/null 2>&1; then
    printf 'populate_workspaces: unable to launch %s\n' "${app_name}" >&2
  fi
}

wait_for_apps_on_workspace() {
  local workspace="$1"
  shift
  local bundles=("$@")

  for _ in {1..30}; do
    local listed
    listed="$(aerospace list-windows --workspace "${workspace}" --format "%{app-bundle-id}" 2>/dev/null || true)"
    local all_found=1
    for bundle in "${bundles[@]}"; do
      if ! grep -q "${bundle}" <<< "${listed}"; then
        all_found=0
        break
      fi
    done
    if [[ ${all_found} -eq 1 ]]; then
      return 0
    fi
    sleep 0.4
  done

  return 1
}

# Give AeroSpace a brief moment to finish initialization before spawning apps.
sleep 1

launch_app "Dia"
launch_app "Slack"
launch_app "WhatsApp"
launch_app "Notion Calendar"
launch_app "Superhuman"
launch_app "Obsidian"
launch_app "Figma"
launch_app "Warp"

if wait_for_apps_on_workspace 1 "company.thebrowser.dia"; then
  aerospace workspace 1
  aerospace layout tiling
fi

if wait_for_apps_on_workspace 2 "com.tinyspeck.slackmacgap" "net.whatsapp.WhatsApp"; then
  aerospace workspace 2
  aerospace layout tiles
  aerospace balance-sizes
fi
