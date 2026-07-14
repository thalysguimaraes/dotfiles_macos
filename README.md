# my macOS dotfiles

## Screenshots
### Terminal (Alacritty)
<p align="center">
  <img src="rice.png" />
<br>
<br>
### Browser (Qutebrowser)
  <img src="qutebrowser.png" />
<br>
<br>
### AltBrowser (Edge)
  <img src="edge.png" />
<br>
<br>
### Music (Spotify)
  <img src="spotify.png" />
<br>
<br>
### Secrets (Bitwarden)
  <img src="bitwarden.png" />
</p>

## really great applications that I use

- Aerospace  
The best tiling window manager for MacOS
https://github.com/nikitabobko/AeroSpace

- Sketchybar  
The highly configurable top bar
https://github.com/FelixKratz/SketchyBar

- Sketchybar configuration  
https://github.com/bfpimentel/nixos.git  
a really good lua scripted Sketchybar configuration  

Make sure to install lua: `brew install lua`  
Modify `.config/sketchybar/items/spaces.lua` according to what spaces you have configured in `aerospace.toml`.  
I added further hints about changing workspace definitions and icons in the `spaces.lua` file.  

- brew  
A Package manager for MacOS that is needed/can be used to install great open source software like Aerospace.   
https://brew.sh/

- Required Font for Sketchybar  
`font-space-mono-nerd-font`

- alacritty   
A fast terminal that lets you disable decorations and activate blur/transparency
https://github.com/alacritty/alacritty

- marta  
Great alternative to Finder which allows vim-style bindings. I "disable" the second pane for now by moving the separator 100% to the right. Does not search for configuration in `.config`, so I symlinked it like this:

`ln -s ~/.config/marta/conf.marco "~/Library/Application Support/org.yanex.marta/conf.marco"`

Change file browser to marta (not sure if it works yet though)  
`defaults write -g NSFileViewer -string org.yanex.marta`

- borders  
see what window is in focus at the moment - it makes a colored border appear
https://github.com/FelixKratz/JankyBorders

- brew packages  
see `brew.txt`

- spicetify  
allows to change the theme of Spotify - not yet happy with the theme  
`spicetify config current_theme Dribbblish color_scheme catppuccin-mocha`  

- Wallpaper  
https://www.reddit.com/r/wallpapers/  
https://www.reddit.com/r/wallpapers/comments/1eibln5/abstract_circle_3840x2160/

## Other information

- Shell  
zsh  
oh-my-zsh  

- Browser  
qutebrowser - A great browser that lets you browse the internet via keyboard/vim controls
https://qutebrowser.com/  
qutebrowser theme - not yet happy with the theme 
https://github.com/gicrisf/qute-city-lights  

## MacOS settings

I also changed a few settings in MacOS because the defaults interfere with this config

### make Dock and the native MacOS bar auto-hide  
Desktop & Dock - Autohide Dock can be here somewhere  
Control Center - Enable menu bar autohide here  

Hide Dock via cli:  
`defaults write com.apple.dock autohide -bool true && killall Dock`  

Make it only appear if you float over it with the mouse for 10 seconds (use 4 fingers up gesture to make it appear)  
`defaults write com.apple.dock autohide-delay -float 10000 && killall Dock`

### disable Dock bouncing of apps
`defaults write com.apple.dock no-bouncing -bool TRUE && killall Dock`  


### disable desktop icons
having desktop icons is not very user-friendly together with tiling window managers and, be honest, it is cluttered most of the time anyways so it is recommended to disable them in "Desktop & Dock"  

### disable window animations
Run in terminal:  
`defaults write -g NSAutomaticWindowAnimationsEnabled -bool false`

### reduce motion (for native fullscreen functionality and maybe some more unnecessary animations)
- System Preferences > Accessibility > Display > Reduce motion

### disable lots of MacOS keyboard shortcuts in the MacOS settings
- disable command+Q in MacOS system settings
- be ready to disable a few more, as I am unsure about what other shortcuts might collide

### Move windows by dragging any part of the window (by holding ctrl+cmd)
Run in terminal:  
`defaults write -g NSWindowShouldDragOnGesture -bool true`

### Displays have separate Spaces
Enable this in MacOS settings "Desktop & dock" or else Sketchybar will not start. In general Aerospace recommends disabling this though.  
Read about it here: https://nikitabobko.github.io/AeroSpace/guide#a-note-on-displays-have-separate-spaces  

Sketchybar might work with the option being disabled in the future.  
https://github.com/FelixKratz/SketchyBar/issues/495  

## Remote execution fabric

The opt-in Orca/Pi remote execution layer lives in [`remote-fabric/`](remote-fabric/README.md). It keeps execution local by default and requires the documented rollout acceptance matrix before remote routing can become the default.

---

## Pi agent configuration

Minha configuração pessoal do [Pi](https://github.com/badlogic/pi-mono), organizada para servir como referência e ponto de partida.

> **Repositório privado:** há configurações opinativas e integrações específicas do meu ambiente. Copie apenas o que fizer sentido para você.

## O que tem aqui

| Caminho | Conteúdo |
| --- | --- |
| `settings.json` | Modelo padrão, nível de thinking, tema, packages e extensões instaladas |
| `models.json` | Provider local do Anthropic via Meridian |
| `mcp.example.json` | Servidores MCP, sem credenciais |
| `keybindings.json` | Atalhos personalizados |
| `cloak.json` | Regras para ocultar segredos no contexto enviado aos modelos |
| `agents/` | Perfis de subagentes (`implementer`, `reviewer` e `scout`) |
| `extensions/` | Extensões locais e ferramentas web |
| `skills/` | Skills reutilizáveis que mantenho localmente |

Arquivos de autenticação, tokens, sessões, diretórios confiáveis e backups foram deliberadamente excluídos.

## Instalação recomendada

Os arquivos globais do Pi ficam em `~/.pi/agent`. Faça backup antes de alterar sua configuração:

```bash
cp -R ~/.pi/agent ~/.pi/agent.backup

git clone git@github.com:thalysguimaraes/dotfiles_macos.git ~/dotfiles_macos
cd ~/dotfiles_macos
```

### 1. Comece pelas configurações principais

Revise os arquivos antes de copiar — principalmente `settings.json`, porque a lista de modelos e packages muda com frequência.

```bash
cp settings.json keybindings.json cloak.json ~/.pi/agent/
cp models.json ~/.pi/agent/ # somente se você também usa Meridian
```

O meu `models.json` espera um proxy Meridian em `http://127.0.0.1:3456`. Se você não usa Meridian, mantenha seu próprio arquivo ou remova esse provider.

### 2. Instale agentes, extensões e skills

Para experimentar tudo:

```bash
mkdir -p ~/.pi/agent/{agents,extensions,skills}
cp -R agents/. ~/.pi/agent/agents/
cp -R extensions/. ~/.pi/agent/extensions/
cp -R skills/. ~/.pi/agent/skills/
```

Sugestão: comece copiando somente os itens que quer testar. Algumas extensões são específicas do meu fluxo com Orca e Meridian:

- `orca-*` e `worker-configuration-guard.ts`: integração com o Orca;
- `meridian-system-prompt-filter.ts`: ajustes para o Meridian;
- `web-tools/`: ferramentas `websearch` e `webfetch`;
- `paste-image-plus.ts`: melhorias ao colar imagens;
- `save-md/`: exportação de conversas para Markdown;
- `pi-cloak/`: proteção adicional para conteúdo sensível.

### 3. Configure os MCPs

Nunca versione tokens diretamente. Use o exemplo como base:

```bash
cp mcp.example.json ~/.pi/agent/mcp.json
```

Depois:

1. substitua `YOUR_FIGMA_ACCESS_TOKEN` localmente;
2. remova servidores que não usa;
3. confirme que o Paper está rodando em `127.0.0.1:29979`, caso queira essa integração;
4. autentique Figma e Linear via OAuth quando o Pi solicitar.

O arquivo real `mcp.json` é ignorado pelo Git.

## Para reproduzir meu harness com Claude

O ponto principal é a combinação abaixo:

1. packages em `settings.json` (MCP, subagentes, todo, goal, context-mode e pi-lens);
2. perfis em `agents/` para delegar implementação, exploração e revisão;
3. `extensions/worker-configuration-guard.ts` para controlar a configuração dos workers;
4. provider Anthropic em `models.json` quando o Meridian estiver disponível;
5. skills em `skills/` para dar instruções especializadas aos agentes.

Depois de copiar os arquivos, reinicie o Pi. Abra primeiro em um projeto descartável e confira se packages, extensões e ferramentas carregaram sem erros antes de usar no trabalho real.

## Atualização sem sobrescrever sua configuração

Em vez de copiar tudo novamente, compare as mudanças:

```bash
cd ~/dotfiles_macos
git pull

diff -u ~/.pi/agent/settings.json settings.json || true
diff -u ~/.pi/agent/mcp.json mcp.example.json || true
```

Aplique apenas os trechos desejados.

## Segurança

Não adicione ao repositório:

- `auth.json`;
- `secrets/`;
- `sessions/`;
- `trust.json`;
- tokens em `mcp.json`;
- backups com credenciais.

Antes de qualquer push, vale rodar:

```bash
git grep -nEi '(api[_-]?key|access[_-]?token|client[_-]?secret|password|bearer)'
```

Os resultados podem incluir exemplos e regras de redaction; revise valores reais, não apenas nomes de campos.
