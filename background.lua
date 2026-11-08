-- 背景图层
-- 壁纸 + 垂直渐变暗色遮罩 + 亚克力
-- 1:1 复刻 Tabby 配置:
--   appearance.opacity: 0.93
--   appearance.vibrancy: true / vibrancyType: fluent
--   hacks.enableFluentBackground: true
--   css: linear-gradient(rgba(0,0,0,0.5), rgba(0,0,0,0.9)) + url(wallpaper) cover/center

local M = {}

-- ======== 可调参数 ========
M.wallpaper = "D:/Data/Pictures/壁纸/HuTao/棺の胡桃ちゃん4k_fa843.jpg"

M.opacity = 0.93          -- 整体窗口不透明度 (Tabby: appearance.opacity)
                          -- < 1.0 时亚克力材质才会透出

M.wallpaper_opacity = 0.6 -- 壁纸层自身不透明度
                          -- 调低 (< 0.9) 可让亚克力模糊更明显

M.acrylic = false          -- 亚克力材质 (Tabby: vibrancyType: fluent)
                          -- 需要 Win11 22H2+; 窗口失焦时毛玻璃会暂时退化为近似纯色

-- 渐变遮罩暗度 (0.0 = 无遮罩, 1.0 = 全黑)
M.overlay = {
  top = 0.65,              -- 窗口顶部遮罩暗度 (Tabby css: rgba(0,0,0,0.5))
  bottom = 0.9,           -- 窗口底部遮罩暗度 (Tabby css: rgba(0, 0, 0, 0.9))
}
-- ========================

return function(config)
  -- 整窗透明度 (透明 + 亚克力的前提)
  config.window_background_opacity = M.opacity
  config.text_background_opacity = 1.0

  -- 背景分层: 先壁纸, 再暗度渐变 (与 Tabby CSS 叠加顺序一致)
  -- 壁纸文件不存在时自动降级为纯渐变背景 (跨机器可移植)
  local layers = {}
  if M.wallpaper and io.open(M.wallpaper, "rb") then
    layers[#layers + 1] = {
      source = { File = M.wallpaper },
      opacity = M.wallpaper_opacity,
      width = "Cover",                 -- css background-size: cover
      height = "Cover",
      horizontal_align = "Center",     -- css background-position: center
      vertical_align = "Middle",
    }
  end
  layers[#layers + 1] = {
    source = {
      Gradient = {
        orientation = "Vertical",
        colors = {
          string.format("rgba(0,0,0,%g)", M.overlay.top),
          string.format("rgba(0,0,0,%g)", M.overlay.bottom),
        },
      },
    },
    width = "100%",
    height = "100%",
  }
  config.background = layers

  -- 亚克力材质 (fluent)
  if M.acrylic then
    config.win32_system_backdrop = "Acrylic"
  end
end
