-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
-- ~/.config/nvim/init.lua

-- Ensure Neovim does not set a specific background color
vim.cmd("highlight Normal guibg=NONE ctermbg=NONE")
vim.cmd("highlight NonText guibg=NONE ctermbg=NONE")
vim.cmd("highlight LineNr guibg=NONE ctermbg=NONE")
vim.cmd("highlight StatusLine guibg=NONE ctermbg=NONE")
vim.cmd("highlight NormalNC guibg=NONE ctermbg=NONE")
vim.cmd("highlight CursorLineNr guibg=NONE ctermbg=NONE")

-- Optional: Set a custom color scheme if needed
-- vim.cmd("colorscheme your_color_scheme")
