-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>cq", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
-- vsplit
vim.keymap.set("n", "<leader>vs", ":vsplit<CR>", { desc = "Open vertical split" })
vim.keymap.set("n", "<A-j>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<A-k>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<A-h>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<A-l>", "<C-w><C-k>", { desc = "Move focus to the upper window" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.api.nvim_set_keymap(
	"n",
	"<leader>wq",
	":bd<CR>:e .<CR>",
	{ noremap = true, silent = true, desc = "Quit to directory list" }
)

-- Gitsigns keymaps
function setup_gitsigns_keymaps(bufnr)
	local gitsigns = require("gitsigns")
	local function map(mode, l, r, opts)
		opts = opts or {}
		opts.buffer = bufnr
		vim.keymap.set(mode, l, r, opts)
	end

	-- Navigation
	map("n", "]c", function()
		if vim.wo.diff then
			vim.cmd.normal({ "]c", bang = true })
		else
			gitsigns.nav_hunk("next")
		end
	end, { desc = "Jump to next git [c]hange" })
	map("n", "[c", function()
		if vim.wo.diff then
			vim.cmd.normal({ "[c", bang = true })
		else
			gitsigns.nav_hunk("prev")
		end
	end, { desc = "Jump to previous git [c]hange" })

	-- Actions
	-- visual mode
	map("v", "<leader>gs", function()
		gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
	end, { desc = "stage git hunk" })
	map("v", "<leader>gr", function()
		gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
	end, { desc = "reset git hunk" })

	-- normal mode
	map("n", "<leader>gs", gitsigns.stage_hunk, { desc = "git [s]tage hunk" })
	map("n", "<leader>gr", gitsigns.reset_hunk, { desc = "git [r]eset hunk" })
	map("n", "<leader>gS", gitsigns.stage_buffer, { desc = "git [S]tage buffer" })
	map("n", "<leader>gu", gitsigns.undo_stage_hunk, { desc = "git [u]ndo stage hunk" })
	map("n", "<leader>gR", gitsigns.reset_buffer, { desc = "git [R]eset buffer" })
	map("n", "<leader>gp", gitsigns.preview_hunk, { desc = "git [p]review hunk" })
	map("n", "<leader>gb", gitsigns.blame_line, { desc = "git [b]lame line" })
	map("n", "<leader>gd", gitsigns.diffthis, { desc = "git [d]iff against index" })
	map("n", "<leader>gD", function()
		gitsigns.diffthis("@")
	end, { desc = "git [D]iff against last commit" })

	-- Toggles
	map("n", "<leader>tb", gitsigns.toggle_current_line_blame, { desc = "[T]oggle git show [b]lame line" })
	map("n", "<leader>tD", gitsigns.toggle_deleted, { desc = "[T]oggle git show [D]eleted" })
end
