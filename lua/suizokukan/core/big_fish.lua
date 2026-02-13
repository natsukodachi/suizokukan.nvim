local M = {}

local render = require("suizokukan.core.render")



--- 大魚エンティティを作成する
---@param config table  プラグイン全体の設定
---@return table 大魚エンティティ
function M.spawn(config)
  local width, height = render.get_editor_size()
  local cfg = config.big_fish

  local dir = math.random(2) == 1 and 1 or -1
  local shapes = dir == 1 and cfg.shapes_right or cfg.shapes_left
  local shape = shapes[math.random(#shapes)]

  -- 画面外から登場させる
  local col
  if dir == 1 then
    col = -#shape - 2
  else
    col = width + 2
  end

  -- 画面中央付近の行に出現
  local min_row = 3
  local max_row = math.max(min_row + 1, height - 6)
  local row = math.random(min_row, max_row)

  local buf = render.create_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { shape })

  local win = render.create_float(buf, row, math.max(0, col), #shape, 1, {
    zindex       = 2,
    winblend     = 25,
    winhighlight = "Normal:SuizokukanBigFish",
  })

  return {
    win   = win,
    buf   = buf,
    row   = row,
    col   = col,
    dir   = dir,
    shape = shape,
  }
end


--- 大魚を1ステップ進める
---@param fish table
---@param config table
---@return boolean alive
function M.move(fish, config)
  local width, _ = render.get_editor_size()

  -- 大魚は速め（1ティックで3列移動）
  fish.col = fish.col + fish.dir * 3

  if fish.dir == 1 and fish.col > width + 10 then
    return false
  elseif fish.dir == -1 and fish.col + #fish.shape < -10 then
    return false
  end

  local display_col = math.max(0, fish.col)
  local display_text = fish.shape

  if fish.col < 0 then
    local offset = -fish.col
    display_text = fish.shape:sub(offset + 1)
    if #display_text == 0 then
      return true
    end
  end

  local ok = render.update_float(
    fish,
    fish.row,
    display_col,
    { display_text },
    math.max(1, #display_text),
    1
  )

  return ok
end


--- 大魚を破棄する
---@param fish table
function M.destroy(fish)
  render.close_float(fish)
end

return M
