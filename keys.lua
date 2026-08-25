-- 快捷键
-- 来自 Tabby hotkeys 完整映射

local wezterm = require("wezterm")
local act = wezterm.action

-- Ctrl-C: 有选中内容时复制, 否则发送 ^C (Tabby 行为)
local function copy_or_send_ctrl_c(window, pane)
  local sel = window:get_selection_text_for_pane(pane)
  if sel and #sel > 0 then
    window:perform_action(act.CopyTo("Clipboard"), pane)
  else
    window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
  end
end

return function(config)
  config.keys = {
    ------------------------------------------------------------------
    -- 复制 / 粘贴
    ------------------------------------------------------------------
    { key = "c", mods = "CTRL", action = wezterm.action_callback(copy_or_send_ctrl_c) },
    { key = "C", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
    { key = "V", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
    { key = "Insert", mods = "SHIFT", action = act.PasteFrom("Clipboard") },

    ------------------------------------------------------------------
    -- 字体缩放
    ------------------------------------------------------------------
    { key = "=", mods = "CTRL", action = act.IncreaseFontSize },
    { key = "=", mods = "CTRL|SHIFT", action = act.IncreaseFontSize },
    { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
    { key = "-", mods = "CTRL|SHIFT", action = act.DecreaseFontSize },
    { key = "0", mods = "CTRL", action = act.ResetFontSize },

    ------------------------------------------------------------------
    -- 搜索
    ------------------------------------------------------------------
    { key = "F", mods = "CTRL|SHIFT", action = act.Search({ CaseInSensitiveString = "" }) },

    ------------------------------------------------------------------
    -- 窗口 / 全屏
    ------------------------------------------------------------------
    { key = "N", mods = "CTRL|SHIFT", action = act.SpawnWindow },
    { key = "F11", action = act.ToggleFullScreen },
    { key = "Enter", mods = "ALT", action = act.ToggleFullScreen },

    ------------------------------------------------------------------
    -- 标签页
    ------------------------------------------------------------------
    { key = "T", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
    { key = "W", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
    {
      -- 重命名标签 (Tabby rename-tab: Ctrl-Shift-R)
      key = "R",
      mods = "CTRL|SHIFT",
      action = act.PromptInputLine({
        description = "输入新的标签名称:",
        action = wezterm.action_callback(function(window, pane, line)
          if line then
            window:active_tab():set_title(line)
          end
        end),
      }),
    },
    { key = "RightArrow", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(1) },
    { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
    { key = "LeftArrow", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },
    { key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },
    { key = "PageUp", mods = "CTRL|SHIFT", action = act.MoveTabRelative(-1) },
    { key = "PageDown", mods = "CTRL|SHIFT", action = act.MoveTabRelative(1) },

    -- Alt+1..0 直达第 1..10 个标签 (Tabby tab-1..tab-10)
    { key = "1", mods = "ALT", action = act.ActivateTab(0) },
    { key = "2", mods = "ALT", action = act.ActivateTab(1) },
    { key = "3", mods = "ALT", action = act.ActivateTab(2) },
    { key = "4", mods = "ALT", action = act.ActivateTab(3) },
    { key = "5", mods = "ALT", action = act.ActivateTab(4) },
    { key = "6", mods = "ALT", action = act.ActivateTab(5) },
    { key = "7", mods = "ALT", action = act.ActivateTab(6) },
    { key = "8", mods = "ALT", action = act.ActivateTab(7) },
    { key = "9", mods = "ALT", action = act.ActivateTab(8) },
    { key = "0", mods = "ALT", action = act.ActivateTab(9) },

    ------------------------------------------------------------------
    -- 分屏 (Tabby split-right / split-bottom)
    ------------------------------------------------------------------
    { key = "D", mods = "CTRL|SHIFT", action = act.SplitPane({ direction = "Right", size = { Percent = 50 } }) },
    { key = "S", mods = "CTRL|SHIFT", action = act.SplitPane({ direction = "Down", size = { Percent = 50 } }) },

    ------------------------------------------------------------------
    -- 窗格导航
    ------------------------------------------------------------------
    { key = "LeftArrow", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Left") },
    { key = "RightArrow", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Right") },
    { key = "UpArrow", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Up") },
    { key = "DownArrow", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Down") },
    -- Tabby pane-nav-previous/next: WezTerm 窗格是空间布局, 改为交互式窗格选择
    { key = "[", mods = "CTRL|ALT", action = act.PaneSelect({}) },
    { key = "]", mods = "CTRL|ALT", action = act.PaneSelect({}) },
    { key = "Enter", mods = "CTRL|ALT", action = act.TogglePaneZoomState },
    { key = "X", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = true }) },

    ------------------------------------------------------------------
    -- 滚动
    ------------------------------------------------------------------
    { key = "PageUp", mods = "CTRL", action = act.ScrollToTop },
    { key = "PageDown", mods = "CTRL", action = act.ScrollToBottom },
    { key = "PageUp", mods = "ALT", action = act.ScrollByPage(-1) },
    { key = "PageDown", mods = "ALT", action = act.ScrollByPage(1) },
    { key = "UpArrow", mods = "CTRL|SHIFT", action = act.ScrollByLine(-1) },
    { key = "DownArrow", mods = "CTRL|SHIFT", action = act.ScrollByLine(1) },

    ------------------------------------------------------------------
    -- 启动器 / 配置 / 命令面板
    ------------------------------------------------------------------
    { key = "T", mods = "CTRL|ALT", action = act.ShowLauncher },                                      -- switch-profile
    { key = "E", mods = "CTRL|SHIFT", action = act.ShowLauncherArgs({ flags = "FUZZY|LAUNCH_MENU_ITEMS" }) }, -- profile-selector
    { key = "P", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette },                             -- command-selector
    {                                                                                                     -- settings: Ctrl-, 打开配置文件
      key = ",",
      mods = "CTRL",
      action = act.SpawnCommandInNewWindow({ args = { "code", "--wait", wezterm.config_file } }),
    },
  }
end
