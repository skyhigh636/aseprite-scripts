-- Canvas Ruler for Aseprite
-- Hover over the preview to see the pixel distance to each edge of the sprite.
-- Click the preview to lock/unlock the measurement point.

local sprite = app.sprite
if not sprite then
  app.alert("Open a sprite first.")
  return
end

local W, H = sprite.width, sprite.height
local MARGIN = 5          -- room around the sprite for labels
local img = nil            -- flattened snapshot of the sprite
local mx, my = nil, nil    -- mouse position (widget coords)
local locked = false

local function snapshot()
  img = Image(W, H)
  img:drawSprite(sprite, app.frame or sprite.frames[1])
end
snapshot()

-- Colors
local C_BG     = Color{ r = 40,  g = 40,  b = 44 }
local C_SPRITE = Color{ r = 70,  g = 70,  b = 76 }
local C_H      = Color{ r = 255, g = 90,  b = 90 }   -- left/right
local C_V      = Color{ r = 80,  g = 200, b = 255 }  -- top/bottom
local C_TEXT   = Color{ r = 255, g = 255, b = 255 }
local C_LABEL  = Color{ r = 0,   g = 0,   b = 0, a = 190 }

-- Layout: fit sprite into canvas, integer zoom when >= 1
local function layout(cw, ch)
  local availW = math.max(1, cw - MARGIN * 2)
  local availH = math.max(1, ch - MARGIN * 2)
  local z = math.min(availW / W, availH / H)
  if z >= 1 then z = math.floor(z) end
  local ox = math.floor((cw - W * z) / 2)
  local oy = math.floor((ch - H * z) / 2)
  return z, ox, oy
end

local function line(ctx, x1, y1, x2, y2, color)
  ctx.color = color
  ctx.strokeWidth = 1
  ctx:beginPath()
  ctx:moveTo(x1, y1)
  ctx:lineTo(x2, y2)
  ctx:stroke()
end

local function label(ctx, text, cx, cy, color)
  local size = ctx:measureText(text)
  local pw, ph = 4, 2
  local x = math.floor(cx - size.width / 2)
  local y = math.floor(cy - size.height / 2)
  ctx.color = C_LABEL
  ctx:fillRect(Rectangle(x - pw, y - ph, size.width + pw * 2, size.height + ph * 2))
  ctx.color = color or C_TEXT
  ctx:fillText(text, x, y)
end

local dlg
dlg = Dialog{
  title = "Canvas Ruler",
  onclose = function()
    sprite.events:off(onSpriteChange)
  end
}

function onSpriteChange()
  snapshot()
  if dlg then dlg:repaint() end
end
sprite.events:on("change", onSpriteChange)

dlg:canvas{
  id = "view",
  width = 420,
  height = 420,
  onpaint = function(ev)
    local ctx = ev.context
    local cw, ch = ctx.width, ctx.height
    local z, ox, oy = layout(cw, ch)

    -- background + sprite
    ctx.color = C_BG
    ctx:fillRect(Rectangle(0, 0, cw, ch))
    ctx.color = C_SPRITE
    ctx:fillRect(Rectangle(ox, oy, math.floor(W * z), math.floor(H * z)))
    ctx:drawImage(img,
      Rectangle(0, 0, W, H),
      Rectangle(ox, oy, math.floor(W * z), math.floor(H * z)))

    if not mx then return end

    -- widget coords -> sprite pixel
    local px = math.floor((mx - ox) / z)
    local py = math.floor((my - oy) / z)
    if px < 0 or py < 0 or px >= W or py >= H then return end

    local left, right = px, W - 1 - px
    local top, bottom = py, H - 1 - py

    -- pixel center & sprite bounds in widget space
    local cx = ox + (px + 0.5) * z
    local cy = oy + (py + 0.5) * z
    local x0, y0 = ox, oy
    local x1, y1 = ox + W * z, oy + H * z

    -- highlight the hovered pixel
    ctx.color = C_TEXT
    ctx.strokeWidth = 1
    ctx:strokeRect(Rectangle(
      math.floor(ox + px * z), math.floor(oy + py * z),
      math.max(1, math.ceil(z)), math.max(1, math.ceil(z))))

    -- ruler lines
    line(ctx, x0, cy, cx, cy, C_H)   -- left
    line(ctx, cx, cy, x1, cy, C_H)   -- right
    line(ctx, cx, y0, cx, cy, C_V)   -- top
    line(ctx, cx, cy, cx, y1, C_V)   -- bottom

    -- distance labels (midpoints of each segment)
    label(ctx, tostring(left),   (x0 + cx) / 2, cy - 10, C_H)
    label(ctx, tostring(right),  (cx + x1) / 2, cy - 10, C_H)
    label(ctx, tostring(top),    cx + 16, (y0 + cy) / 2, C_V)
    label(ctx, tostring(bottom), cx + 16, (cy + y1) / 2, C_V)

    -- coordinate readout
    local info = string.format("x:%d y:%d  of  %dx%d%s",
      px, py, W, H, locked and "  [locked]" or "")
    label(ctx, info, cw / 2, 14, C_TEXT)
  end,
  onmousemove = function(ev)
    if not locked then
      mx, my = ev.x, ev.y
      dlg:repaint()
    end
  end,
  onmousedown = function(ev)
    locked = not locked
    if not locked then
      mx, my = ev.x, ev.y
    end
    dlg:repaint()
  end,
}

dlg:button{
  text = "Refresh",
  onclick = function()
    snapshot()
    dlg:repaint()
  end
}
dlg:button{ text = "Close", onclick = function() dlg:close() end }

dlg:show{ wait = false }