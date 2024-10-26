-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>cq", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

vim.keymap.set("n", "<A-j>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<A-k>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<A-h>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<A-l>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- vim.api.nvim_set_keymap("n", "s", "<nop>", { noremap = true, silent = true })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

vim.api.nvim_set_keymap(
	"n",
	"<leader>wq",
	":bd<CR>:e .<CR>",
	{ noremap = true, silent = true, desc = "Quit to directory list" }
)
