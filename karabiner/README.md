# Karabiner-Elements Configuration

## Hyper Key Setup

This configuration remaps Caps Lock to a Hyper key (⌘ + ⌃ simultaneously).

## Installation

1. Install Karabiner-Elements:
   ```bash
   brew install --cask karabiner-elements
   ```

2. Link this configuration:
   ```bash
   ln -sf ~/Developer/personal/dotfiles_macos/karabiner ~/.config/karabiner
   ```

3. Grant necessary permissions when prompted:
   - Input Monitoring
   - Accessibility

4. Restart Karabiner-Elements or your Mac

## What It Does

- **Caps Lock** → **Hyper Key** (cmd+ctrl combined)
- Creates a unique modifier namespace for Aerospace window management
- Eliminates conflicts with native macOS and application shortcuts
- Allows adding shift and alt modifiers on top for extended combinations

## Usage with Aerospace

See `~/Obsidian/Hyper Key Setup Guide.md` for complete keybinding reference.

Quick examples:
- `Caps Lock + h/j/k/l` → Focus windows (cmd-ctrl-h/j/k/l)
- `Caps Lock + 1-8` → Switch workspaces (cmd-ctrl-1-8)
- `Caps Lock + Shift + h/j/k/l` → Move windows (cmd-ctrl-shift-h/j/k/l)

## Configuration

File: `karabiner.json`

Current profile: "Hyper Key"
- Caps Lock → Left Control + Left Command

## Customization

To map a different key to Hyper, edit `karabiner.json` and change:
```json
"from": {
  "key_code": "caps_lock"  // Change this
}
```

Common alternatives:
- `right_command`
- `right_option`
- `right_shift`
- `f19`
