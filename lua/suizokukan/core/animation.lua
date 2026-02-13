
local M = {}

local config_mod   = require("suizokukan.config")
local render       = require("suizokukan.core.render")
local fish_mod     = require("suizokukan.core.fish")
local big_fish_mod = require("suizokukan.core.big_fish")
local bubbles_mod  = require("suizokukan.core.bubbles")
local seafloor_mod = require("suizokukan.core.seafloor")

-------------------------------------------------------
-- 内部状態
-------------------------------------------------------

local state = {
  running      = false,
  fish         = {},     
  big_fish     = nil,   
  bubbles      = {},     
  seafloor     = nil,    
  timers       = {},     -- { fish, big_fish, big_fish_spawn, bubble }
  augroup      = nil,    -- autocmd グループ ID
  last_topline = 0,      -- スクロール検知用
  bubble_cooldown = false, -- 泡塊が画面中部に達するまで生成を抑制
}

-------------------------------------------------------
-- 小魚管理
-------------------------------------------------------

--- 消滅済みの魚を除去し、目標数まで新規生成する
local function maintain_fish()
  local cfg = config_mod.get()
  local count = cfg.fish.count or 5

  -- 生存中の魚だけ残す
  local alive = {}
  for _, f in ipairs(state.fish) do
    if f.win and vim.api.nvim_win_is_valid(f.win) then
      alive[#alive + 1] = f
    end
  end
  state.fish = alive

  -- 追加生成
  while #state.fish < count do
    local ok, f = pcall(fish_mod.spawn, cfg)
    if ok and f then
      state.fish[#state.fish + 1] = f
    else
      break
    end
  end
end

--- 更新
--- 画面外の魚を破棄する
local function update_fish()
  local cfg = config_mod.get()
  local alive = {}

  for _, f in ipairs(state.fish) do
    local ok = fish_mod.move(f, cfg)
    if ok then
      alive[#alive + 1] = f
    else
      fish_mod.destroy(f)
    end
  end

  state.fish = alive
  maintain_fish()
end

-------------------------------------------------------
-- 大魚管理
-------------------------------------------------------

--- 大魚を出現させる
local function try_spawn_big_fish()
  local cfg = config_mod.get()
  if not cfg.big_fish.enabled then return end
  if state.big_fish then return end  -- 同時に1匹のみ

  local ok, bf = pcall(big_fish_mod.spawn, cfg)
  if ok and bf then
    state.big_fish = bf
  end
end

--- 更新
--- 画面外なら破棄する
local function update_big_fish()
  if not state.big_fish then return end
  local cfg = config_mod.get()

  local ok = big_fish_mod.move(state.big_fish, cfg)
  if not ok then
    big_fish_mod.destroy(state.big_fish)
    state.big_fish = nil
  end
end

-------------------------------------------------------
-- 泡管理
-------------------------------------------------------

--- 更新
--- 全泡を上方へ移動し、画面上端に達したものを破棄する
local function update_bubbles()
  local alive = {}
  local _, height = render.get_editor_size()
  local mid = math.floor(height / 2)
  local any_below_mid = false

  for _, b in ipairs(state.bubbles) do
    local ok = bubbles_mod.move(b)
    if ok then
      alive[#alive + 1] = b
      if b.row > mid then
        any_below_mid = true
      end
    else
      bubbles_mod.destroy(b)
    end
  end
  state.bubbles = alive

  -- 全泡が画面中部より上に達したらクールダウン解除
  if state.bubble_cooldown and not any_below_mid then
    state.bubble_cooldown = false
  end
end

--- スクロールに応じて泡塊を生成する（k〜k+3列 × 4〜6行 に約15個）
---@param scroll_amount number  おおよそのスクロール行数
local function on_scroll(scroll_amount)
  local cfg = config_mod.get()
  if not cfg.bubbles.enabled then return end
  if state.bubble_cooldown then return end

  -- 20% の確率でのみ泡塊を生成
  if math.random(100) > 20 then return end

  local max_count = cfg.bubbles.max_count or 15

  -- 泡塊の基準列をランダムに決定
  local width = render.get_editor_size()
  local base_col = math.random(0, math.max(0, width - 4))

  -- 4-6行分の高さにわたって泡を配置
  local cluster_rows = math.random(3, 6)
  local spawned = 0

  for row_offset = 0, cluster_rows - 1 do
    -- 各行に0-3個の泡を配置
    local per_row = math.random(0, 3)
    for _ = 1, per_row do
      if #state.bubbles >= max_count then break end
      local ok, b = pcall(bubbles_mod.spawn, cfg, base_col, row_offset)
      if ok and b then
        state.bubbles[#state.bubbles + 1] = b
        spawned = spawned + 1
      end
    end
    if #state.bubbles >= max_count then break end
  end

  -- 泡を生成したらクールダウン開始
  if spawned > 0 then
    state.bubble_cooldown = true
  end
end

-------------------------------------------------------
-- タイマー
-------------------------------------------------------

---@param timer userdata|nil
local function stop_timer(timer)
  if not timer then return end
  pcall(function()
    timer:stop()
    if not timer:is_closing() then
      timer:close()
    end
  end)
end

-------------------------------------------------------

--- 水族館アニメーションを開始する
function M.start()
  if state.running then return end
  state.running = true

  local cfg = config_mod.get()

  -- ハイライトグループ設定
  render.setup_highlights()

  -- 乱数シード初期化
  math.randomseed(os.time())

  -- 海底
  if cfg.seafloor.enabled then
    local ok, sf = pcall(seafloor_mod.create, cfg)
    if ok and sf then
      state.seafloor = sf
    end
  end

  -- 初期の魚を配置
  maintain_fish()

  -- 小魚タイマー 
  state.timers.fish = vim.loop.new_timer()
  state.timers.fish:start(
    cfg.fish.speed,
    cfg.fish.speed,
    vim.schedule_wrap(function()
      if not state.running then return end
      pcall(update_fish)
    end)
  )

  -- 大魚タイマー
  if cfg.big_fish.enabled then
    local interval_ms = (cfg.big_fish.interval_sec or 180) * 1000

    -- 出現チェック
    state.timers.big_fish_spawn = vim.loop.new_timer()
    state.timers.big_fish_spawn:start(
      interval_ms,
      interval_ms,
      vim.schedule_wrap(function()
        if not state.running then return end
        pcall(try_spawn_big_fish)
      end)
    )

    -- 移動タイマー（big_fish.speed 間隔）
    state.timers.big_fish = vim.loop.new_timer()
    state.timers.big_fish:start(
      cfg.big_fish.speed,
      cfg.big_fish.speed,
      vim.schedule_wrap(function()
        if not state.running then return end
        pcall(update_big_fish)
      end)
    )
  end

  -- 泡移動タイマー
  if cfg.bubbles.enabled then
    state.timers.bubble = vim.loop.new_timer()
    state.timers.bubble:start(
      cfg.bubbles.speed,
      cfg.bubbles.speed,
      vim.schedule_wrap(function()
        if not state.running then return end
        pcall(update_bubbles)
      end)
    )
  end

  -- オートコマンド
  state.augroup = vim.api.nvim_create_augroup("Suizokukan", { clear = true })

  -- スクロール検知して泡を生成
  vim.api.nvim_create_autocmd("WinScrolled", {
    group = state.augroup,
    callback = function()
      if not state.running then return end
      local topline = vim.fn.line("w0")
      local diff = math.abs(topline - state.last_topline)
      state.last_topline = topline
      if diff > 0 then
        pcall(on_scroll, diff)
      end
    end,
  })

  -- 画面リサイズで海底を再描画
  vim.api.nvim_create_autocmd("VimResized", {
    group = state.augroup,
    callback = function()
      if not state.running then return end
      if state.seafloor and cfg.seafloor.enabled then
        pcall(seafloor_mod.refresh, state.seafloor, cfg)
      end
    end,
  })

  -- 初期 topline を記録
  state.last_topline = vim.fn.line("w0")
end

--- 水族館を停止し、全リソースを解放する
function M.stop()
  state.running = false

  -- 全タイマーを停止
  for name, timer in pairs(state.timers) do
    stop_timer(timer)
    state.timers[name] = nil
  end

  -- オートコマンドを削除
  if state.augroup then
    pcall(vim.api.nvim_del_augroup_by_id, state.augroup)
    state.augroup = nil
  end

  -- 小魚を破棄
  for _, f in ipairs(state.fish) do
    pcall(fish_mod.destroy, f)
  end
  state.fish = {}

  -- 大魚を破棄
  if state.big_fish then
    pcall(big_fish_mod.destroy, state.big_fish)
    state.big_fish = nil
  end

  -- 泡を破棄
  for _, b in ipairs(state.bubbles) do
    pcall(bubbles_mod.destroy, b)
  end
  state.bubbles = {}

  -- 海底を破棄
  if state.seafloor then
    pcall(seafloor_mod.destroy, state.seafloor)
    state.seafloor = nil
  end
end

--- アニメーションが実行中かどうかを返す
---@return boolean
function M.is_running()
  return state.running
end

return M
