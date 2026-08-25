-- 标签页渲染: Tabby 风格程序图标 + 标题截断 + 悬停反馈
-- 通过 format-tab-title 事件完全自定义标签内容
--
-- 图标说明:
--   1. SVG 图标: WezTerm 标签栏只能渲染文字字形 (不支持内嵌图片),
--      icons/*.svg 由 icons/build_icon_font.py 编译成矢量字形字体
--      (fonts/wezterm-config-icons.ttf, 码点见 icons/generated.lua)。
--      下方带 svg 字段的条目优先使用; 字体未生成时自动回退 Nerd Font。
--   2. Nerd Font 字形: 下方所有 Unicode 码点均已对照本机
--      JetBrainsMonoNerdFont 的字形表 (glyph names) 逐一核实。
--      查找更多图标: https://www.nerdfonts.com/cheat-sheet
--      (本机字形名参考: D:/Data/Desktop/PiTest/glyphs.txt)

local wezterm = require("wezterm")

-- SVG 图标码点表 (自动生成); 缺失时为 nil, 回退 Nerd Font 字形
local ok, SVG_ICONS = pcall(require, "icons.generated")
if not ok then SVG_ICONS = nil end

-- =================== 图标定义 ===================
-- glyph = Nerd Font 字形, color = 图标颜色, svg = SVG 图标名 (优先)
local I = {
  powershell  = { glyph = "\u{e86c}", color = "#5391FE", svg = "powershell" },
  cmd         = { glyph = "\u{e795}", color = "#cccccc", svg = "cmd" },
  terminal    = { glyph = "\u{e795}", color = "#c8c8c8" },  -- dev-terminal (>_)
  bash        = { glyph = "\u{e760}", color = "#8DC149" },  -- dev-bash
  zsh         = { glyph = "\u{e84f}", color = "#89e051" },  -- dev-ohmyzsh
  fish        = { glyph = "\u{ee41}", color = "#4EC9B0" },  -- fa-fish
  linux       = { glyph = "\u{e712}", color = "#FCC624" },  -- dev-linux (Tux)
  ubuntu      = { glyph = "\u{e73a}", color = "#E95420" },  -- dev-ubuntu
  debian      = { glyph = "\u{e77d}", color = "#A80030" },  -- dev-debian
  arch        = { glyph = "\u{e732}", color = "#1793D1" },  -- dev-archlinux
  fedora      = { glyph = "\u{e7d9}", color = "#51A2DA" },  -- dev-fedora
  ssh         = { glyph = "\u{e8b1}", color = "#f97316" },  -- dev-ssh
  git         = { glyph = "\u{e702}", color = "#F05032" },  -- dev-git
  vim         = { glyph = "\u{e62b}", color = "#019833" },  -- custom-vim
  neovim      = { glyph = "\u{e83a}", color = "#57A143" },  -- dev-neovim
  node        = { glyph = "\u{e719}", color = "#83CD29" },  -- dev-nodejs
  python      = { glyph = "\u{e73c}", color = "#4B8BBE" },  -- dev-python
  docker      = { glyph = "\u{e7b0}", color = "#2496ED" },  -- dev-docker
  java        = { glyph = "\u{e738}", color = "#f89820" },  -- dev-java
  go          = { glyph = "\u{e626}", color = "#00ADD8" },  -- custom-go
  rust        = { glyph = "\u{e7a8}", color = "#dea584" },  -- dev-rust
  ruby        = { glyph = "\u{e739}", color = "#CC342D" },  -- dev-ruby
  php         = { glyph = "\u{e73d}", color = "#7377AD" },  -- dev-php
  mysql       = { glyph = "\u{e704}", color = "#4479A1" },  -- dev-mysql
  postgres    = { glyph = "\u{e76e}", color = "#336791" },  -- dev-postgresql
  sqlite      = { glyph = "\u{e7c4}", color = "#003B57" },  -- dev-sqlite
  mongodb     = { glyph = "\u{e7a4}", color = "#4FAA41" },  -- dev-mongodb
  redis       = { glyph = "\u{e76d}", color = "#DC382D" },  -- dev-redis
  vscode      = { glyph = "\u{e8da}", color = "#22A7F0" },  -- dev-vscode
  visualstudio= { glyph = "\u{e70c}", color = "#512BD4" },  -- dev-visualstudio
  dotnet      = { glyph = "\u{e77f}", color = "#512BD4" },  -- dev-dotnet
  kubernetes  = { glyph = "\u{e81d}", color = "#326CE5" },  -- dev-kubernetes
  lua         = { glyph = "\u{e826}", color = "#51a0cf" },  -- dev-lua
  perl        = { glyph = "\u{e769}", color = "#0298C3" },  -- dev-perl
  typescript  = { glyph = "\u{e8ca}", color = "#3178C6" },  -- dev-typescript
  cpp         = { glyph = "\u{e61d}", color = "#f34b7d" },  -- custom-cpp
  flutter     = { glyph = "\u{e7dd}", color = "#40C4FF" },  -- dev-flutter
  adb         = { glyph = "\u{e70e}", color = "#3DDC84" },  -- dev-android (安卓小绿人)
}

-- 进程名 -> 图标 (键 = basename 去掉 .exe, 小写)
local icon_by_process = {
  -- Shell
  powershell = I.powershell,  pwsh = I.powershell,  pwshpreview = I.powershell,
  cmd = I.cmd, conhost = I.cmd, openconsole = I.cmd,
  bash = I.bash, sh = I.bash, dash = I.bash, msys = I.bash, mintty = I.bash,
  zsh = I.zsh, fish = I.fish, nu = I.terminal,
  -- Linux / WSL
  wsl = I.linux, wslhost = I.linux, vmmem = I.linux, systemd = I.linux,
  -- 远程
  ssh = I.ssh, scp = I.ssh, sftp = I.ssh, telnet = I.terminal, mosh = I.ssh,
  -- 开发工具
  git = I.git, gitk = I.git, tig = I.git, lazygit = I.git,
  vim = I.vim, nvim = I.neovim, neovide = I.neovim, helix = I.neovim,
  code = I.vscode, code_insiders = I.vscode, devenv = I.visualstudio, rider = I.visualstudio,
  -- 语言运行时 / 包管理
  node = I.node, npm = I.node, npx = I.node, pnpm = I.node, yarn = I.node,
  bun = I.node, deno = I.node,
  python = I.python, pythonw = I.python, python3 = I.python, py = I.python,
  pip = I.python, pip3 = I.python, uv = I.python, poetry = I.python, conda = I.python,
  java = I.java, javaw = I.java, mvn = I.java, gradle = I.java, kotlin = I.java,
  go = I.go, dlv = I.go,
  rustc = I.rust, cargo = I.rust, rustup = I.rust, rust_analyzer = I.rust,
  ruby = I.ruby, irb = I.ruby, gem = I.ruby,
  php = I.php, composer = I.php, artisan = I.php,
  lua = I.lua, luajit = I.lua,
  perl = I.perl,
  tsc = I.typescript, tsnode = I.typescript, deno_ = I.typescript,
  gcc = I.cpp, cc = I.cpp, gxx = I.cpp, clang = I.cpp, clangpp = I.cpp, cl = I.cpp,
  flutter = I.flutter, dart = I.flutter,
  dotnet = I.dotnet,
  -- 服务 / 数据库
  docker = I.docker, docker_compose = I.docker, podman = I.docker,
  kubectl = I.kubernetes, k9s = I.kubernetes, helm = I.kubernetes,
  mysql = I.mysql, mysqld = I.mysql, mariadb = I.mysql,
  psql = I.postgres, postgres = I.postgres,
  sqlite3 = I.sqlite, mongod = I.mongodb, mongosh = I.mongodb,
  redis_server = I.redis, redis_cli = I.redis, valkey_server = I.redis,
  nginx = I.terminal, apache = I.terminal,
  -- 其他
  adb = I.adb, fastboot = I.adb,
  far = I.terminal, explorer = I.terminal,
}

-- pane 标题关键词回退匹配 (顺序敏感: 越具体越靠前)
local icon_by_title_keyword = {
  { "nvim",      I.neovim },
  { "neovim",    I.neovim },
  { "vim",       I.vim },
  { "helix",     I.neovim },
  { "powershell",I.powershell },
  { "pwsh",      I.powershell },
  { "命令提示符", I.terminal },
  { "cmd",       I.terminal },
  { "git bash",  I.bash },
  { "mingw",     I.bash },
  { "msys",      I.bash },
  { "bash",      I.bash },
  { "zsh",       I.zsh },
  { "fish",      I.fish },
  { "ssh",       I.ssh },
  { "sftp",      I.ssh },
  { "docker",    I.docker },
  { "kubectl",   I.kubernetes },
  { "python",    I.python },
  { "node",      I.node },
  { "npm",       I.node },
  { "yarn",      I.node },
  { "cargo",     I.rust },
  { "rust",      I.rust },
  { "mysql",     I.mysql },
  { "psql",      I.postgres },
  { "postgres",  I.postgres },
  { "sqlite",    I.sqlite },
  { "mongo",     I.mongodb },
  { "redis",     I.redis },
  { "git",       I.git },
  { "wsl",       I.linux },
  { "ubuntu",    I.ubuntu },
  { "debian",    I.debian },
  { "arch",      I.arch },
  { "fedora",    I.fedora },
  { "linux",     I.linux },
}

-- 未匹配时的默认图标
local default_icon = I.terminal

-- 标题最大 UTF-8 字符数 (额外保险, 实际以 tab_max_width 为准)
local max_title_length = 30

-- ==================================================

--- 取进程 basename (去路径与 .exe 后缀, 小写)
local function process_key(name)
  if not name then return nil end
  return name:lower():match("([^/\\]+)%.exe$") or name:lower():match("([^/\\]+)$")
end

--- 从标签信息推断图标: 先按进程名精确匹配, 再按标题关键词回退
local function get_icon(tab)
  local pane = tab.active_pane
  local key = process_key(pane.foreground_process_name)
  if key and icon_by_process[key] then
    return icon_by_process[key]
  end
  local title = (pane.title or ""):lower()
  for _, kv in ipairs(icon_by_title_keyword) do
    if title:find(kv[1], 1, true) then
      return kv[2]
    end
  end
  return default_icon
end

--- 取图标的实际字形: 优先 SVG 编译字形, 否则 Nerd Font 字形
local function icon_glyph(icon)
  if icon.svg and SVG_ICONS and SVG_ICONS[icon.svg] then
    return SVG_ICONS[icon.svg]
  end
  return icon.glyph
end

--- 估算一个 UTF-8 字符的显示宽度 (CJK/全角 = 2, 其他 = 1)
local function char_width(ch)
  local cp = utf8.codepoint(ch)
  if (cp >= 0x1100 and cp <= 0x115F)
  or (cp >= 0x2E80 and cp <= 0x303E)
  or (cp >= 0x3041 and cp <= 0x33FF)
  or (cp >= 0x3400 and cp <= 0x4DBF)
  or (cp >= 0x4E00 and cp <= 0x9FFF)
  or (cp >= 0xA000 and cp <= 0xA4CF)
  or (cp >= 0xAC00 and cp <= 0xD7A3)
  or (cp >= 0xF900 and cp <= 0xFAFF)
  or (cp >= 0xFE10 and cp <= 0xFE19)
  or (cp >= 0xFE30 and cp <= 0xFE6F)
  or (cp >= 0xFF00 and cp <= 0xFF60)
  or (cp >= 0xFFE0 and cp <= 0xFFE6)
  or (cp >= 0x1F300 and cp <= 0x1F64F)
  or (cp >= 0x1F900 and cp <= 0x1F9FF)
  or (cp >= 0x20000 and cp <= 0x3FFFD) then
    return 2
  end
  return 1
end

--- 从右侧截断: 超宽时左侧加省略号, 保留右侧内容 (对路径类标题更友好)
--- budget 为显示宽度 (单元格数)
local function truncate_right(title, budget)
  local chars = {}
  for ch in title:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    chars[#chars + 1] = ch
  end
  local total = 0
  for _, ch in ipairs(chars) do total = total + char_width(ch) end
  if total <= budget then return title end
  -- 预留省略号宽度, 从尾部往前累计
  local keep, w = 0, char_width("\u{2026}")
  for i = #chars, 1, -1 do
    local cw = char_width(chars[i])
    if w + cw > budget then break end
    w = w + cw
    keep = keep + 1
  end
  local out = {}
  for i = #chars - keep + 1, #chars do out[#out + 1] = chars[i] end
  return "\u{2026}" .. table.concat(out)
end

-- 注册标签格式化事件
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local icon  = get_icon(tab)
  local title = tab.active_pane.title or "New Tab"

  -- 图标占 2 格 (图标 + 空格), 其余留给标题
  local budget = (max_width or 30) - 2
  if budget > max_title_length then budget = max_title_length end
  if budget < 6 then budget = 6 end
  title = truncate_right(title, budget)

  -- 三态前景色: 激活 / 悬停 / 普通
  local fg
  if tab.is_active then
    fg = "#f1f1f1"
  elseif hover then
    fg = "#d6d6d6"
  else
    fg = "#8a8a8a"
  end

  -- 注意: FormatItem 每个元素只能有一个键 (Foreground / Background / Text 必须拆开),
  -- 否则 wezterm 会忽略整个 format-tab-title 回退到默认标题
  return {
    { Text = " " },
    -- 图标 (品牌色, 优先 SVG 编译字形)
    { Foreground = { Color = icon.color } },
    { Text = icon_glyph(icon) },
    { Text = " " },
    -- 标题
    { Foreground = { Color = fg } },
    { Text = title },
    { Text = " " },
  }
end)

-- 模块接口 (保留扩展点)
return function(config)
end
