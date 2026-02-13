# 🐠 suizokukan.nvim



NeoVim の背景でゆったり魚が泳ぐ、軽量水族館プラグインです。
コーディングの休憩時にどうぞ。


## 📦 Install

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "natsukodachi/suizokukan.nvim",
  config = function()
    require("suizokukan").setup()
  end,
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "natsukodachi/suizokukan.nvim",
  config = function()
    require("suizokukan").setup()
  end,
}
```

### [dein.vim](https://github.com/Shougo/dein.vim)

**dein.toml**
```toml
[[plugins]]
repo = 'natsukodachi/suizokukan.nvim'
hook_add = '''
lua require("suizokukan").setup()
'''
```

**Vim script**
```vim
call dein#add('natsukodachi/suizokukan.nvim')
```

```lua
require("suizokukan").setup()
```


## ⚙️ Setup


```lua
require("suizokukan").setup({
  -- true にすると起動時に自動で有効化
  enabled = true,

  -- 小さい魚の設定
  fish = {
    count = 5,            -- 同時に泳ぐ魚の最大数
    speed = 600,          -- 移動間隔 (ms)
    min_row = 1,          -- 魚が出現する最小行 (0-indexed)
    max_row_offset = 4,   -- 下端確保の行数
  },

  -- 大きい魚の設定
  big_fish = {
    enabled = true,
    interval_sec = 180,   -- 平均出現間隔
    speed = 200,          -- 1コマの移動間隔 (ms)
  },

  -- 泡アニメーション
  bubbles = {
    enabled = true,
    max_count = 15,       -- 同時に表示する泡の最大数
    speed = 200,          -- 泡の上昇間隔 (ms)
    chars = { ".", "o", "O", "°" },
  },

  -- 海底
  seafloor = {
    enabled = true,
    height = 1,           -- 海底の行数
  },
})
```

すべてのオプションは省略可能で、デフォルト値が使われます。


## 🕹️ Usage

| コマンド              | 説明                     |
| --------------------- | ------------------------ |
| `:SuizokukanEnable`   | 有効化           |
| `:SuizokukanDisable`  | 無効化           |
| `:SuizokukanToggle`   | ON / OFF を切り替え      |



## 🐟 Customize

### ハイライトグループ
`:set termguicolors`で色が付きますが、カラースキームと競合する場合があります。
以下のハイライトグループで色を変更できます。

| グループ名             | 対象           | デフォルト色 |
| ---------------------- | -------------- | ------------ |
| `SuizokukanFish`       | 小さい魚       | `#5f87af`    |
| `SuizokukanBigFish`    | 大きい魚       | `#5f5faf`    |
| `SuizokukanBubble`     | 泡             | `#87afdf`    |
| `SuizokukanSeafloor`   | 海底（砂・岩） | `#af8754`    |
| `SuizokukanCoral`      | サンゴ         | `#d75f87`    |
| `SuizokukanSeaweed`    | 海藻           | `#5faf5f`    |


```lua
vim.api.nvim_set_hl(0, "SuizokukanFish", { fg = "#8888cc" })
```

### 魚の形

`fish.shapes_right` / `fish.shapes_left` を設定すると、独自の魚を追加できます。

```lua
require("suizokukan").setup({
  fish = {
    shapes_right = { "><>", "><>>", ">=>" },
    shapes_left  = { "<><", "<<><", "<=<" },
  },
})
```


## 📝 動作要件

**NeoVim 0.9+**
- Windows / macOS / Linux

外部依存はありません。
