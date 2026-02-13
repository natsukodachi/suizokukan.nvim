local M = {}

--- デフォルト設定
M.defaults = {
  enabled = true,

  fish = {
    count = 5,            -- 小魚の最大数
    speed = 600,          -- 移動間隔 (ms)
    min_row = 1,          -- 魚の出現最小行
    max_row_offset = 4,   -- 下端の予約行数（ステータスラインと被らない）
    shapes_right = {      
      "><>",
      "><>>",
      "><(('> ",
    },
    shapes_left = {       
      "<><",
      "<<><",
      " <')>><",
    },
  },

  big_fish = {
    enabled = true,
    interval_sec = 180,   -- 平均出現間隔（秒）
    speed = 200,          -- 移動間隔 (ms)
    shapes_right = {
      "><((((*>",
      "}>=>=>=>=>",
    },
    shapes_left = {
      "<*)))))><",
      "<=<=<=<=<{",
    },
  },

  bubbles = {
    enabled = true,
    max_count = 15,       -- 同時表示する泡の上限
    speed = 200,          -- 泡の上昇間隔 (ms)
    chars = { ".", "o", "O", "°" },
  },

  seafloor = {
    enabled = true,
    height = 1,           -- 海底の行数
  },

  background = "#161821", -- 背景色

  performance = {
    max_windows = 4,      -- アニメーションを有効にする最大ウィンドウ数
  },
}


M.current = nil


---@param base table
---@param override table
---@return table
local function deep_merge(base, override)
  local result = {}
  for k, v in pairs(base) do
    if type(v) == "table" and type(override[k]) == "table" then
      result[k] = deep_merge(v, override[k])
    elseif override[k] ~= nil then
      result[k] = override[k]
    else
      result[k] = vim.deepcopy(v)
    end
  end
  -- override にしかないキーも含める
  for k, v in pairs(override) do
    if result[k] == nil then
      result[k] = v
    end
  end
  return result
end

--- ユーザー設定を適用する
---@param opts? table
function M.setup(opts)
  if opts then
    M.current = deep_merge(M.defaults, opts)
  else
    M.current = vim.deepcopy(M.defaults)
  end
end

--- 現在の設定を取得する（未設定ならデフォルトで初期化）
---@return table
function M.get()
  if not M.current then
    M.current = vim.deepcopy(M.defaults)
  end
  return M.current
end

return M
