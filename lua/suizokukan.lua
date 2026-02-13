local M = {}

-- 二重読み込み防止
if vim.g.loaded_suizokukan then
  return M
end
vim.g.loaded_suizokukan = true

local config    = require("suizokukan.config")
local animation = require("suizokukan.core.animation")


--- ユーザー設定を適用し、コマンドを登録する
---@param opts? table
function M.setup(opts)
  config.setup(opts)

  vim.api.nvim_create_user_command("SuizokukanEnable", function()
    M.enable()
  end, { desc = "enable aquarium animation" })

  vim.api.nvim_create_user_command("SuizokukanDisable", function()
    M.disable()
  end, { desc = "disable aquarium animation" })

  vim.api.nvim_create_user_command("SuizokukanToggle", function()
    M.toggle()
  end, { desc = "toggle aquarium animation" })

  -- enabled が true なら起動後に自動で有効化
  if config.get().enabled then
    vim.defer_fn(function()
      M.enable()
    end, 500)
  end
end


--- 水族館を有効化する
function M.enable()
  if not animation.is_running() then
    animation.start()
    vim.notify("Suizokukan enabled 🐟", vim.log.levels.INFO)
  end
end


--- 水族館を無効化する
function M.disable()
  if animation.is_running() then
    animation.stop()
    vim.notify("Suizokukan disabled", vim.log.levels.INFO)
  end
end


--- 水族館の ON/OFF を切り替える
function M.toggle()
  if animation.is_running() then
    M.disable()
  else
    M.enable()
  end
end

return M
