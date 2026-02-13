local M = {}

local render = require("suizokukan.core.render")


local elements = {
  sand    = {"_", "~", "_,_","__" },
  rocks   = { "o", "O" },
  coral   = { "Y", "Ψ", "(*)" },
  seaweed = { "|", "l", "!"},
}


--- 海底1行分のテキストとハイライト範囲を生成する
---@param width number
---@return string line
---@return table hl_ranges  { col, len, group } のリスト
function M.generate_line(width)
  local parts = {}
  local hl_ranges = {}
  local col = 0

  while col < width do
    local r = math.random(100)
    local char, group

    if r <= 50 then
      char  = elements.sand[math.random(#elements.sand)]
      group = "SuizokukanSeafloor"
    elseif r <= 70 then
      char  = elements.rocks[math.random(#elements.rocks)]
      group = "SuizokukanSeafloor"
    elseif r <= 85 then
      char  = elements.coral[math.random(#elements.coral)]
      group = "SuizokukanCoral"
    else
      char  = elements.seaweed[math.random(#elements.seaweed)]
      group = "SuizokukanSeaweed"
    end

    parts[#parts + 1] = char
    hl_ranges[#hl_ranges + 1] = { col = col, len = #char, group = group }
    col = col + #char
  end

  return table.concat(parts), hl_ranges
end

--- バッファにハイライト範囲を適用する
---@param buf number
---@param line_idx number
---@param ranges table
local function apply_highlights(buf, line_idx, ranges)
  for _, hl in ipairs(ranges) do
    pcall(
      vim.api.nvim_buf_add_highlight,
      buf, -1, hl.group,
      line_idx, hl.col, hl.col + hl.len
    )
  end
end



---@class SeafloorState
---@field win number|nil
---@field buf number|nil

--- 画面下部に海底フローティングウィンドウを作成する
---@param config table  プラグイン全体の設定
---@return SeafloorState
function M.create(config)
  local width, height = render.get_editor_size()
  local sf_height = config.seafloor.height or 1

  -- 行を生成
  local lines = {}
  local all_hl = {}
  for i = 1, sf_height do
    local line, hl = M.generate_line(width)
    lines[i] = line
    all_hl[i] = hl
  end

  local buf = render.create_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- 文字単位のハイライトを適用
  for i, ranges in ipairs(all_hl) do
    apply_highlights(buf, i - 1, ranges)
  end

  local row = height - sf_height
  local win = render.create_float(buf, row, 0, width, sf_height, {
    zindex       = 1,
    winblend     = 20,
    winhighlight = "Normal:SuizokukanSeafloor",
  })

  return { win = win, buf = buf }
end

--- リサイズ後に海底の位置と内容を更新する
---@param state SeafloorState
---@param config table
function M.refresh(state, config)
  if not state or not state.win or not vim.api.nvim_win_is_valid(state.win) then
    return
  end

  local width, height = render.get_editor_size()
  local sf_height = config.seafloor.height or 1

  -- 内容を再生成（幅が変わった可能性がある）
  local lines = {}
  local all_hl = {}
  for i = 1, sf_height do
    local line, hl = M.generate_line(width)
    lines[i] = line
    all_hl[i] = hl
  end

  local row = height - sf_height
  render.update_float(state, row, 0, lines, width, sf_height)

  -- ハイライトを再適用
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_clear_namespace(state.buf, -1, 0, -1)
    for i, ranges in ipairs(all_hl) do
      apply_highlights(state.buf, i - 1, ranges)
    end
  end
end

--- 海底を破棄する
---@param state SeafloorState
function M.destroy(state)
  render.close_float(state)
end

return M
