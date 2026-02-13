local M = {}
local config = require("suizokukan.config")

--- デフォルトのハイライトグループを設定する
function M.setup_highlights()
  local cfg = config.get()
  local bg = cfg.background or "#161821"
  local highlights = {
    SuizokukanFish     = { fg = "#5f87af", ctermfg = 67,  bg = bg, ctermbg = "NONE", default = true },
    SuizokukanBigFish  = { fg = "#5f5faf", ctermfg = 61,  bg = bg, ctermbg = "NONE", default = true },
    SuizokukanBubble   = { fg = "#87afdf", ctermfg = 110, bg = bg, ctermbg = "NONE", default = true },
    SuizokukanSeafloor = { fg = "#af8754", ctermfg = 137, bg = bg, ctermbg = "NONE", default = true },
    SuizokukanCoral    = { fg = "#d75f87", ctermfg = 168, bg = bg, ctermbg = "NONE", default = true },
    SuizokukanSeaweed  = { fg = "#5faf5f", ctermfg = 71,  bg = bg, ctermbg = "NONE", default = true },
  }
  for name, def in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, def)
  end
end


--- フローティングウィンドウ用のスクラッチバッファを作成する
---@return number bufnr
function M.create_buf()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  return buf
end



--- Floating Windowを作成する
---@param buf number    バッファハンドル
---@param row number    行位置（0始まり、エディタ基準）
---@param col number    列位置（0始まり、エディタ基準）
---@param width number  ウィンドウ幅（>= 1）
---@param height number ウィンドウ高さ（>= 1）
---@param opts? table   追加オプション: zindex, winblend, winhighlight
---@return number|nil win_id
function M.create_float(buf, row, col, width, height, opts)
  opts = opts or {}
  width = math.max(1, math.floor(width))
  height = math.max(1, math.floor(height))

  local ok, win = pcall(vim.api.nvim_open_win, buf, false, {
    relative  = "editor",
    row       = row,
    col       = col,
    width     = width,
    height    = height,
    style     = "minimal",
    focusable = false,
    zindex    = opts.zindex or 1,
    noautocmd = true,
  })
  if not ok or not win then
    return nil
  end

  vim.wo[win].winblend = opts.winblend or 30
  vim.wo[win].winhighlight = opts.winhighlight or "Normal:SuizokukanFish"

  return win
end

--- Floating Windowの位置と内容を更新する
--- entity には win, buf フィールドが必要
---@param entity table  { win, buf }
---@param row number
---@param col number
---@param lines string[]
---@param width number
---@param height number
---@return boolean success
function M.update_float(entity, row, col, lines, width, height)
  if not entity.win or not vim.api.nvim_win_is_valid(entity.win) then
    return false
  end
  if not entity.buf or not vim.api.nvim_buf_is_valid(entity.buf) then
    return false
  end

  width = math.max(1, math.floor(width))
  height = math.max(1, math.floor(height))

  local ok = pcall(vim.api.nvim_win_set_config, entity.win, {
    relative = "editor",
    row      = row,
    col      = col,
    width    = width,
    height   = height,
  })
  if not ok then
    return false
  end

  pcall(vim.api.nvim_buf_set_lines, entity.buf, 0, -1, false, lines)
  return true
end

---Floating Windowを閉じ、entity を無効化する
---@param entity table { win, buf }
function M.close_float(entity)
  if entity.win and vim.api.nvim_win_is_valid(entity.win) then
    pcall(vim.api.nvim_win_close, entity.win, true)
  end
  entity.win = nil
  entity.buf = nil
end


--- 使用可能なエディタの幅と高さを返す
---@return number width, number height
function M.get_editor_size()
  local width = vim.o.columns
  -- コマンドライン高さ + ステータスライン 1 行分を引く
  local height = vim.o.lines - vim.o.cmdheight - 1
  if height < 4 then height = 4 end
  return width, height
end

return M
