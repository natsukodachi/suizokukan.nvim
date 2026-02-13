local M = {}

local render = require("suizokukan.core.render")


--- 画面下部付近に泡を1つ生成する
---@param config table  プラグイン全体の設定
---@param base_col number  泡塊の基準列（この列から +3 の範囲内に配置）
---@param row_offset number?  開始行のオフセット（0=最下部、正で上にずらす）
---@return table 泡エンティティ
function M.spawn(config, base_col, row_offset)
  local width, height = render.get_editor_size()
  local cfg = config.bubbles

  local chars = cfg.chars
  local char = chars[math.random(#chars)]

  local col_max = math.min(base_col + 3, width - 1)
  local col = math.random(base_col, col_max)

  local row = height - 2 - (row_offset or 0)

  local buf = render.create_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { char })

  local win = render.create_float(buf, row, col, #char, 1, {
    zindex       = 1,
    winblend     = 40,
    winhighlight = "Normal:SuizokukanBubble",
  })

  return {
    win  = win,
    buf  = buf,
    row  = row,
    col  = col,
    char = char,
    life = 0,
  }
end


--- 泡を1行上に移動させる
---@param bubble table
---@return boolean alive
function M.move(bubble)
  bubble.row = bubble.row - 1
  bubble.life = bubble.life + 1

  -- わずかなゆらぎ
  if math.random(3) == 1 then
    bubble.col = bubble.col + (math.random(2) == 1 and 1 or -1)
    bubble.col = math.max(0, bubble.col)
  end

  -- 画面上端に到達したら消滅する
  if bubble.row < 0 then
    return false
  end

  local ok = render.update_float(
    bubble,
    bubble.row,
    bubble.col,
    { bubble.char },
    #bubble.char,
    1
  )

  return ok
end


--- 泡を破棄する
---@param bubble table
function M.destroy(bubble)
  render.close_float(bubble)
end

return M
