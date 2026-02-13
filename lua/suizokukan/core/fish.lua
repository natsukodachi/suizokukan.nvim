local M = {}

local render = require("suizokukan.core.render")

---@class SuizokukanFish
---@field win   number|nil  フローティングウィンドウハンドル
---@field buf   number|nil  バッファハンドル
---@field row   number      現在の行（0始まり）
---@field col   number      現在の列（負数や画面外もあり得る）
---@field dir   number      1 = 右方向, -1 = 左方向
---@field shape string      この魚のAA
---@field drift number      ランダム速度係数（0.8 – 1.2）



--- 新しい小魚エンティティを作成する
---@param config table  プラグイン全体の設定
---@return SuizokukanFish
function M.spawn(config)
  local width, height = render.get_editor_size()
  local cfg = config.fish

  local min_row = cfg.min_row or 1
  local max_row = height - (cfg.max_row_offset or 4)
  if max_row <= min_row then max_row = min_row + 1 end

  -- ランダムな方向を決める
  local dir = math.random(2) == 1 and 1 or -1
  local shapes = dir == 1 and cfg.shapes_right or cfg.shapes_left
  local shape = shapes[math.random(#shapes)]

  -- 画面外から登場させる
  local col
  if dir == 1 then
    col = 0                   -- 左端から登場
  else
    col = width - #shape      -- 右端から登場
  end

  local row = math.random(min_row, max_row)

  -- Floating Windowを作成
  local buf = render.create_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { shape })

  local win = render.create_float(buf, row, math.max(0, col), #shape, 1, {
    zindex       = 1,
    winblend     = 35,
    winhighlight = "Normal:SuizokukanFish",
  })

  return {
    win   = win,
    buf   = buf,
    row   = row,
    col   = col,
    dir   = dir,
    shape = shape,
    drift = math.random(80, 120) / 100,
  }
end


--- 魚を1ステップ進める
---@param fish SuizokukanFish
---@param config table
---@return boolean alive  画面内にまだいるかどうか
function M.move(fish, config)
  local width, _ = render.get_editor_size()

  local step = math.max(1, math.floor(2 * fish.drift))
  fish.col = fish.col + fish.dir * step

  -- 画面外チェック
  if fish.dir == 1 and fish.col > width then
    return false
  elseif fish.dir == -1 and (fish.col + #fish.shape) < 0 then
    return false
  end

  -- 表示列を 0 以上にクランプ（フローティングウィンドウの制約）
  local display_col = math.max(0, fish.col)
  local display_text = fish.shape

  -- 左端からはみ出ている場合、形状をトリミング
  if fish.col < 0 then
    local offset = -fish.col
    display_text = fish.shape:sub(offset + 1)
    if #display_text == 0 then
      return true  -- まだ生存中だが、表示はまだ
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


--- 魚のフローティングウィンドウを閉じる
---@param fish SuizokukanFish
function M.destroy(fish)
  render.close_float(fish)
end

return M
