-- 外观: 标签栏 / 窗口边距 / 窗口装饰
-- Tabby 风格标签页 + WinUI 风格窗口控制按钮
--
-- 标签栏 (fancy 栏):
--   1. 栏高可调 : fancy 栏高度 = 标签字体行高 x 1.75, 由 window_frame.font_size
--                 驱动。150% 缩放 (144dpi) 下 ≈ 4.7 x font_size(pt) 像素:
--                 8.0 -> ~38px, 9.0 -> ~42px, 10.0 -> ~47px
--                 (retro 栏高度只能跟随终端字体, 无法单独调高, 故弃用)
--   2. 标签字体 : window_frame.font = 微软雅黑 (仅 fancy 栏生效)
--   3. 透明     : 标签栏/非激活标签底色全透明, 与壁纸融合
--   4. 单 tab 宽度上限 : tab_max_width 限制单个标签, 不限制整条标签栏总长
--   5. 激活标签: 轻微加暗背景以区分 (colors.tab_bar, 见下)

local wezterm = require("wezterm")
local utils  = require("utils")

return function(config)
  -- 标签栏基础
  config.enable_tab_bar = true
  config.hide_tab_bar_if_only_one_tab = false
  config.show_new_tab_button_in_tab_bar = true
  config.use_fancy_tab_bar = true       -- 高度/字体可调的原生风格标签栏
  config.tab_max_width = 30             -- 单个标签最大宽度; 整体不限
  config.show_tab_index_in_tab_bar = false

  -- 自定义图标字体加载目录 (icons/*.svg 由 icons/build_icon_font.py 编译而来)
  config.font_dirs = { "fonts" }

  -- 移除原生标题栏, 控制按钮融入标签栏; WinUI 风格右上角按钮
  -- (Windows 样式内置 WinUI 交互: 关闭键悬停红底白字,
  --   最小化/最大化悬停 10% 亮度蒙层, 图标细线字形)
  config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
  config.integrated_title_button_style = "Windows"
  config.integrated_title_button_color = "Auto"  -- 随标题栏深浅自动取黑/白

  -- 标签字体 (仅 fancy 栏生效)
  -- 回退链: Microsoft YaHei (标签文字)
  --       -> WezTerm Config Icons (icons/*.svg 编译的 PUA 图标)
  --       -> JetBrainsMono NF (其余 Nerd Font 图标)
  local tab_font = wezterm.font_with_fallback(
    { "Microsoft YaHei", "WezTerm Config Icons", "JetBrainsMono NF" },
    { bold = false }
  )

  config.window_frame = {
    font = tab_font,
    font_size = 9.0,   -- 调栏高/字号: 见文件头换算表 (9.0 ≈ 42px @150%)
    -- 标题栏透明, 直接透出壁纸
    active_titlebar_bg   = "rgba(0, 0, 0, 0)",
    inactive_titlebar_bg = "rgba(0, 0, 0, 0)",
    -- 去掉标签栏与终端之间的分隔线
    active_titlebar_border_bottom   = "rgba(0, 0, 0, 0)",
    inactive_titlebar_border_bottom = "rgba(0, 0, 0, 0)",
    -- 注: window_frame.button_* 颜色仅对 Wayland CSD 生效;
    --     Windows 集成按钮的 WinUI 悬停配色是内置的, 无需配置
  }

  -- 根据系统深浅色自动适配
  local is_dark = utils.get_appearance():find("Dark") ~= nil

  -- 标签栏颜色 (覆盖当前配色方案中的标签页部分)
  config.colors = {
    tab_bar = {
      -- 整条标签栏透明 (fancy 栏底色实际由 window_frame.*_titlebar_bg 决定)
      background = "rgba(0, 0, 0, 0)",

      -- 激活标签: 轻微加暗背景 + 亮字
      active_tab = {
        bg_color  = "rgba(0, 0, 0, 0.25)",
        fg_color  = is_dark and "#f1f1f1" or "#4a465c",
      },
      inactive_tab = {
        bg_color = "rgba(0, 0, 0, 0)",
        fg_color = is_dark and "#8a8a8a" or "#9893a5",
      },
      inactive_tab_hover = {
        bg_color = "rgba(0, 0, 0, 0.15)",
        fg_color = is_dark and "#d6d6d6" or "#6e6a86",
      },

      -- 标签之间的分隔 (仅 retro 栏生效, fancy 栏忽略)
      inactive_tab_edge = "rgba(0, 0, 0, 0)",

      -- 新建标签按钮
      new_tab = {
        bg_color = "rgba(0, 0, 0, 0)",
        fg_color = is_dark and "#8a8a8a" or "#9893a5",
      },
      new_tab_hover = {
        bg_color = "rgba(0, 0, 0, 0.15)",
        fg_color = is_dark and "#d6d6d6" or "#6e6a86",
      },
    },
  }

  config.window_padding = { left = 18, right = 18, top = 6, bottom = 6 }
end
