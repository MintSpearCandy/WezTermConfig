#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 icons/*.svg 编译成 WezTerm 标签栏可用的图标字体 (TrueType)。

背景: WezTerm 的标签栏 (format-tab-title) 只能渲染文本字形,
不支持内嵌图片/SVG。想要 "SVG 图标" 唯一的办法是把 SVG 的矢量
轮廓编译成字体字形, 放在 Unicode 私有区补充面 (U+F0000..,
Plane 15 PUA-A; Nerd Font 不占用该区, 避免回退链撞字形),
再通过 window_frame.font 的 fallback 链渲染。

用法:
    py icons/build_icon_font.py

读取: icons/*.svg          (按 ICONS 中声明的 fills/holes 索引取轮廓)
输出: fonts/wezterm-config-icons.ttf   (字体, 由 config.font_dirs 加载)
      icons/generated.lua              (图标名 -> 码点映射, tabs.lua 使用)

注意: 字形是单色的, 颜色在 tabs.lua 里用 Foreground 指定
      (等效于 SVG 的品牌色)。

新增图标: 放一个 xxx.svg 到 icons/, 在下面 ICONS 里声明
    "xxx": dict(fills=[...], holes=[...], color="#rrggbb")
fills/holes 为 SVG 中可绘制元素 (path/rect/line/...) 的出现顺序索引
(0 起, <defs> 内的非形状元素不计)。fills = 实心部分, holes = 镂空部分。
fill="none" 且带 stroke 的元素会自动按描边宽度展开成轮廓。
"""

import math
import os
import sys
import xml.etree.ElementTree as ET

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
from svgpathtools import parse_path

HERE = os.path.dirname(os.path.abspath(__file__))
FONT_DIR = os.path.join(HERE, "..", "fonts")
FONT_PATH = os.path.join(FONT_DIR, "wezterm-config-icons.ttf")
LUA_PATH = os.path.join(HERE, "generated.lua")

FAMILY = "WezTerm Config Icons"   # appearance.lua fallback 链里引用的名字
BASE_CP = 0xF0000                  # 码点基准 (Plane 15 PUA-A, 避开 Nerd Font)
UNITS_PER_EM = 1000
ASCENT, DESCENT = 700, 300        # 单元格高 = 1.0em, 由主字体 cell 缩放对齐
MAX_W, MAX_H = 880, 850           # 图标在 em 框内的最大占位 (icon ≈ 85% 行高)
CENTER_Y = 300                    # 图标垂直中心 (基线上方 0.3em)
CURVE_SAMPLES = 24                # 曲线/圆弧采样密度

# 每个图标的轮廓声明 (索引 = SVG 文档中可绘制元素顺序, 0 起)
ICONS = {
    "cmd": dict(
        fills=[0],        # 圆角方块背景
        holes=[1, 2],     # ">" 折线 + "_" 下划线 (描边元素, 自动展开)
    ),
    "powershell": dict(
        fills=[0],        # 外壳 (两层渐变轮廓几乎重合, 只取一层,
                          #        否则同向叠叠加绕数, 镂空会失效)
        holes=[3],        # 白色 ">_" (镂空, 保住 PS logo 的剪影)
    ),
}

DRAWABLE = {"path", "rect", "circle", "ellipse", "line", "polyline", "polygon"}


# ---------------------------------------------------------------- SVG 解析

def local_name(tag):
    return tag.rsplit("}", 1)[-1]


def svg_elements(svg_file):
    """返回 SVG 中可绘制元素列表: [(tag, attrib), ...] (文档顺序, 跳过 <defs>)"""
    root = ET.parse(svg_file).getroot()
    out = []
    for el in root.iter():
        name = local_name(el.tag)
        if name in DRAWABLE and local_name(el.tag) and name != "defs":
            out.append((name, el.attrib))
    return out


def sample_segment(seg, n=CURVE_SAMPLES):
    """把一条 path 线段折线化 (含首尾端点)"""
    if seg.__class__.__name__ == "Line":
        p, q = seg.start, seg.end
        return [(p.real, p.imag), (q.real, q.imag)]
    pts = []
    for i in range(n + 1):
        p = seg.point(i / n)
        pts.append((p.real, p.imag))
    return pts


def dedupe(pts):
    out = [pts[0]]
    for p in pts[1:]:
        if abs(p[0] - out[-1][0]) > 1e-6 or abs(p[1] - out[-1][1]) > 1e-6:
            out.append(p)
    return out


def path_subpaths(d):
    """path d 属性 -> 子路径折线列表 [[(x,y),...], ...] (按 M/断点分组)"""
    segs = parse_path(d)
    subpaths, cur = [], []
    prev_end = None
    for seg in segs:
        start = (seg.start.real, seg.start.imag)
        if prev_end is None or (abs(start[0] - prev_end[0]) > 1e-6
                                or abs(start[1] - prev_end[1]) > 1e-6):
            if cur:
                subpaths.append(cur)
            cur = [start]
        cur.extend(sample_segment(seg))
        prev_end = (seg.end.real, seg.end.imag)
    if cur:
        subpaths.append(dedupe(cur))
    return subpaths


def arc_points(cx, cy, rx, ry, a0, a1, n=CURVE_SAMPLES):
    return [(cx + rx * math.cos(a0 + (a1 - a0) * i / n),
             cy + ry * math.sin(a0 + (a1 - a0) * i / n)) for i in range(n + 1)]


def rect_subpaths(x, y, w, h, rx, ry):
    """矩形 (可带圆角) -> 单条闭合折线 (屏幕顺时针)"""
    rx = min(rx or 0, w / 2)
    ry = min(ry or 0, h / 2)
    if rx <= 0 and ry <= 0:
        return [[(x, y), (x + w, y), (x + w, y + h), (x, y + h)]]
    rx = rx or ry
    ry = ry or rx
    # 四个圆角 (屏幕顺时针): 中心 + 起止角 (SVG y 向下, 角度顺时针增加)
    corners = [
        ((x + w - rx, y + ry), -math.pi / 2, 0.0),            # 右上
        ((x + w - rx, y + h - ry), 0.0, math.pi / 2),         # 右下
        ((x + rx, y + h - ry), math.pi / 2, math.pi),         # 左下
        ((x + rx, y + ry), math.pi, 3 * math.pi / 2),         # 左上
    ]
    pts = []
    for (cx, cy), a0, a1 in corners:
        pts.extend(arc_points(cx, cy, rx, ry, a0, a1))
    return [pts]


def points_attr(s):
    return [tuple(map(float, p.split(","))) for p in s.replace(",", " ").split() if p]


def element_subpaths(tag, attrib):
    """单个 SVG 元素 -> (子路径折线列表, 是否描边元素, 描边宽度)"""
    fill = attrib.get("fill", "black").strip()
    stroke = attrib.get("stroke")
    # line/polyline 等不闭合形状无法填充, 有 stroke 就按描边展开
    unclosed = tag in ("line", "polyline")
    stroked = (fill.lower() == "none" or unclosed) and stroke is not None
    sw = float(attrib.get("stroke-width", "1") or 1)
    if tag == "path":
        subs = path_subpaths(attrib["d"])
    elif tag == "rect":
        x, y = float(attrib.get("x", 0)), float(attrib.get("y", 0))
        w, h = float(attrib["width"]), float(attrib["height"])
        subs = rect_subpaths(x, y, w, h,
                             float(attrib.get("rx", 0) or 0),
                             float(attrib.get("ry", 0) or 0))
    elif tag == "line":
        subs = [[(float(attrib["x1"]), float(attrib["y1"])),
                 (float(attrib["x2"]), float(attrib["y2"]))]]
    elif tag == "circle":
        cx, cy, r = (float(attrib["cx"]), float(attrib["cy"]),
                     float(attrib["r"]))
        subs = [arc_points(cx, cy, r, r, 0, 2 * math.pi)]
    elif tag == "ellipse":
        cx, cy = float(attrib["cx"]), float(attrib["cy"])
        subs = [arc_points(cx, cy, float(attrib["rx"]), float(attrib["ry"]),
                           0, 2 * math.pi)]
    elif tag in ("polyline", "polygon"):
        subs = [points_attr(attrib["points"])]
        if tag == "polygon":
            subs[0].append(subs[0][0])
    else:
        subs = []
    return subs, stroked, sw


# ---------------------------------------------------------------- 几何工具

def sub(a, b):
    return (a[0] - b[0], a[1] - b[1])


def unit(v):
    l = math.hypot(*v)
    return (v[0] / l, v[1] / l) if l > 1e-12 else (0.0, 0.0)


def stroke_contour(pts, w):
    """折线按描边宽度 w 展开成闭合轮廓 (miter join, 限长 2.5h)"""
    h = w / 2.0
    left, right = [], []
    n = len(pts)
    if n < 2:
        return None
    for i, p in enumerate(pts):
        normals = []
        if i > 0:
            d = sub(pts[i], pts[i - 1])
            normals.append((-d[1] / max(math.hypot(*d), 1e-12),
                            d[0] / max(math.hypot(*d), 1e-12)))
        if i < n - 1:
            d = sub(pts[i + 1], pts[i])
            normals.append((-d[1] / max(math.hypot(*d), 1e-12),
                            d[0] / max(math.hypot(*d), 1e-12)))
        mx = sum(nn[0] for nn in normals)
        my = sum(nn[1] for nn in normals)
        mlen = math.hypot(mx, my)
        if mlen < 1e-9:
            mx, my, mlen = normals[0][0], normals[0][1], 1.0
        # miter 长度 = h * 2/mlen, 限制不超过 2.5h
        k = min(2.0 / (mlen * mlen), 2.5)
        ox, oy = mx * h * k, my * h * k
        left.append((p[0] + ox, p[1] + oy))
        right.append((p[0] - ox, p[1] - oy))
    return left + right[::-1]


def signed_area(pts):
    s = 0.0
    for a, b in zip(pts, pts[1:] + pts[:1]):
        s += a[0] * b[1] - b[0] * a[1]
    return s / 2.0


def build_glyph_contours(svg_file, spec):
    """SVG -> 字体坐标下的轮廓列表 [(点列表, 是否镂空), ...]"""
    elements = svg_elements(svg_file)

    # 先取出需要给元素, 按其联合 bbox 适配图标框 (忽略设计稿 viewBox 的留白)
    picked = {}
    for idx in list(spec.get("fills", [])) + list(spec.get("holes", [])):
        picked[idx] = element_subpaths(*elements[idx])

    xs, ys = [], []
    for subs, _s, _w in picked.values():
        for poly in subs:
            for x, y in poly:
                xs.append(x)
                ys.append(y)
    bx, by = min(xs), min(ys)
    bw, bh = max(xs) - bx, max(ys) - by
    scale = min(MAX_W / bw, MAX_H / bh)

    # SVG y 向下, 字体 y 向上
    def tx(x, y):
        return (500.0 + (x - bx - bw / 2) * scale,
                CENTER_Y + (by + bh - y - bh / 2) * scale)

    contours = []

    def add_contour(idx, hole):
        subs, stroked, sw = picked[idx]
        for poly in subs:
            if stroked:
                c = stroke_contour([tx(*p) for p in poly], sw * scale)
                if not c:
                    continue
                a = signed_area(c)
                if abs(a) < 1e-6:
                    continue
                if (hole and a < 0) or (not hole and a > 0):
                    c = c[::-1]          # 实心统一 CW(负), 镂空统一 CCW(正)
                contours.append((c, hole))
            else:
                pts = [tx(*p) for p in poly]
                a = signed_area(pts)
                if abs(a) < 1e-6:
                    continue
                if (hole and a < 0) or (not hole and a > 0):
                    pts = pts[::-1]
                contours.append((pts, hole))

    # 注意: nonzero 绕叠规则下, 同向重叠的实心轮廓会叠加绕数,
    # 镂空只抵消一层 -> fills 里避免重叠同向轮廓
    for i in spec.get("fills", []):
        add_contour(i, False)
    for i in spec.get("holes", []):
        add_contour(i, True)
    return contours


# ---------------------------------------------------------------- 字体生成

def main():
    os.makedirs(FONT_DIR, exist_ok=True)

    names = sorted(ICONS)
    cmap = {}
    glyph_order = [".notdef"]
    glyphs = {}
    metrics = {".notdef": (UNITS_PER_EM, 0)}
    glyph_set = {}

    for i, name in enumerate(names):
        svg_file = os.path.join(HERE, name + ".svg")
        contours = build_glyph_contours(svg_file, ICONS[name])
        pen = TTGlyphPen(glyph_set)
        xmin = UNITS_PER_EM
        for pts, _hole in contours:
            pen.moveTo(pts[0])
            for p in pts[1:]:
                pen.lineTo(p)
            pen.closePath()
            xmin = min(xmin, min(p[0] for p in pts))
        gname = "icon-%s" % name
        cp = BASE_CP + i
        glyph_order.append(gname)
        cmap[cp] = gname
        glyphs[gname] = pen.glyph()
        metrics[gname] = (UNITS_PER_EM, int(xmin))
        print("  %-12s -> U+%05X  (%d contours)" % (name, cp, len(contours)))

    fb = FontBuilder(UNITS_PER_EM, isTTF=True)
    fb.setupGlyphOrder(glyph_order)
    fb.setupCharacterMap(cmap)
    glyphs.setdefault(".notdef", TTGlyphPen(glyph_set).glyph())
    fb.setupGlyf(glyphs)
    fb.setupHorizontalMetrics(metrics)
    fb.setupHorizontalHeader(ascent=ASCENT, descent=-DESCENT)
    fb.setupNameTable({
        "familyName": FAMILY,
        "styleName": "Regular",
        "uniqueFontIdentifier": "%s Regular 1.0" % FAMILY,
        "fullName": FAMILY,
        "psName": "WezTermConfigIcons",
        "version": "Version 1.0",
    })
    fb.setupOS2(sTypoAscender=ASCENT, sTypoDescender=-DESCENT,
                usWinAscent=ASCENT, usWinDescent=DESCENT)
    fb.setupPost()
    fb.save(FONT_PATH)
    print("font -> %s" % os.path.normpath(FONT_PATH))

    with open(LUA_PATH, "w", encoding="utf-8", newline="\n") as f:
        f.write("-- 本文件由 icons/build_icon_font.py 自动生成, 请勿手改\n")
        f.write("-- 图标字体: %s (U+%05X 起的私有区码点)\n" % (FAMILY, BASE_CP))
        f.write("return {\n")
        for i, name in enumerate(names):
            f.write('  %s = "\\u{%x}",\n' % (name, BASE_CP + i))
        f.write("}\n")
    print("map  -> %s" % os.path.normpath(LUA_PATH))


if __name__ == "__main__":
    sys.exit(main())
