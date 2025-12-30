-- Clear highlights on search when pressing <Esc> in normal modekey
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Vertical split
vim.keymap.set("n", "<leader>sv", ":vsplit<CR>", { desc = "[V]ertical split" })

-- Window navigation
vim.keymap.set("n", "<A-j>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<A-k>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<A-h>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<A-l>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- Close buffer and return to directory
vim.keymap.set("n", "<leader>wq", ":bd<CR>:e .<CR>", { desc = "Quit to directory list" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Diagnostics
vim.keymap.set("n", "<leader>cq", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Buffer navigation
vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "[B]uffer [N]ext" })
vim.keymap.set("n", "<leader>bp", ":bprevious<CR>", { desc = "[B]uffer [P]revious" })

function setup_telescope_keymaps()
	local builtin = require("telescope.builtin")

	vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "[F]ind [H]elp" })
	vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "[F]ind [K]eymaps" })
	vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "[F]ind [F]iles" })
	vim.keymap.set("n", "<leader>fs", builtin.builtin, { desc = "[F]ind [S]elect Telescope" })
	vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "[F]ind current [W]ord" })
	vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "[F]ind by [G]rep" })
	vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "[F]ind [D]iagnostics" })
	vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "[F]ind [R]esume" })
	vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "[F]ind existing [B]uffers" })
	vim.keymap.set("n", "<leader>fo", builtin.buffers, { desc = "[F]ind [O]ld Files" })

	-- Fuzzy search in current buffer
	vim.keymap.set("n", "<leader>/", function()
		builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
			winblend = 10,
			previewer = false,
		}))
	end, { desc = "[/] Fuzzily search in current buffer" })

	-- Live grep in open files
	vim.keymap.set("n", "<leader>f/", function()
		builtin.live_grep({
			grep_open_files = true,
			prompt_title = "Live Grep in Open Files",
		})
	end, { desc = "[F]ind [/] in Open Files" })

	-- Search Neovim config files
	vim.keymap.set("n", "<leader>fn", function()
		builtin.find_files({ cwd = vim.fn.stdpath("config") })
	end, { desc = "[F]ind [N]eovim files" })
end

-- COLORIZER

function setup_colorizer_keymaps()
	local function toggle_colorizer()
		if vim.g.colorizer_enabled then
			vim.cmd("HighlightColors Off")
			vim.g.colorizer_enabled = false
			print("Colorizer disabled")
		else
			vim.cmd("HighlightColors On")
			vim.g.colorizer_enabled = true
			print("Colorizer enabled")
		end
	end

	vim.keymap.set("n", "<leader>cc", toggle_colorizer, { desc = "Toggle [C]olorizer" })
end

-- LSP

function setup_lsp_keymaps(event)
	local map = function(keys, func, desc, mode)
		mode = mode or "n"
		vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
	end

	-- Navigation
	map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
	map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
	map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
	map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
	map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

	-- Symbols
	map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
	map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

	-- Actions
	map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
	map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })

	-- Diagnostics
	map("<leader>ct", _G.toggle_diagnostics, "[T]oggle Diagnostics")
	map("<leader>cd", vim.diagnostic.open_float, "Show line diagnostics")

	map("<leader>e", function()
		local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
		if #diagnostics > 0 then
			local message = diagnostics[1].message
			vim.fn.setreg("+", message)
		else
			vim.notify("cooked", vim.log.levels.WARN)
		end
	end, "Yank line diagnostics")

	-- Inlay hints toggle
	local client = vim.lsp.get_client_by_id(event.data.client_id)
	if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
		map("<leader>ci", function()
			vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
		end, "Toggle [I]nlay Hints")
	end
end

-- CONFORM

function setup_conform_keymaps()
	vim.keymap.set("", "<leader>F", function()
		require("conform").format({ async = true, lsp_format = "fallback" })
	end, { desc = "[F]ormat buffer" })
end

-- HARPOON

function setup_harpoon_keymaps()
	local mark = require("harpoon.mark")
	local ui = require("harpoon.ui")

	-- Configure which-key to ignore these
	local wk = require("which-key")
	wk.add({
		{ "<leader>a", hidden = true },
		{ "<leader>q", hidden = true },
		{ "<leader>n", hidden = true },
		{ "<leader>p", hidden = true },
		{ "<leader>0", hidden = true },
		{ "<leader>1", hidden = true },
		{ "<leader>2", hidden = true },
		{ "<leader>3", hidden = true },
		{ "<leader>4", hidden = true },
		{ "<leader>5", hidden = true },
		{ "<leader>6", hidden = true },
		{ "<leader>7", hidden = true },
		{ "<leader>8", hidden = true },
		{ "<leader>9", hidden = true },
	})

	vim.keymap.set("n", "<leader>a", mark.add_file)
	vim.keymap.set("n", "<leader>q", ui.toggle_quick_menu)
	vim.keymap.set("n", "<leader>n", ui.nav_next)
	vim.keymap.set("n", "<leader>p", ui.nav_prev)
	for i = 0, 9 do
		vim.keymap.set("n", "<leader>" .. i, function()
			ui.nav_file(i)
		end)
	end
end

-- GITSIGNS

function setup_gitsigns_keymaps(bufnr)
	local gitsigns = require("gitsigns")
	-- Helper function to set buffer-local keymaps
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

	-- Actions (visual mode)
	map("v", "<leader>gs", function()
		gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
	end, { desc = "stage git hunk" })

	map("v", "<leader>gr", function()
		gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
	end, { desc = "reset git hunk" })

	-- Actions (normal mode)
	map("n", "<leader>gs", gitsigns.stage_hunk, { desc = "git [s]tage hunk" })
	map("n", "<leader>gr", gitsigns.reset_hunk, { desc = "git [r]eset hunk" })
	map("n", "<leader>gS", gitsigns.stage_buffer, { desc = "git [S]tage buffer" })
	map("n", "<leader>gR", gitsigns.reset_buffer, { desc = "git [R]eset buffer" })
	map("n", "<leader>gp", gitsigns.preview_hunk, { desc = "git [p]review hunk" })
	map("n", "<leader>gb", gitsigns.blame_line, { desc = "git [b]lame line" })
	map("n", "<leader>gd", gitsigns.diffthis, { desc = "git [d]iff against index" })
	map("n", "<leader>gD", function()
		gitsigns.diffthis("@")
	end, { desc = "git [D]iff against last commit" })

	-- Toggles
	map("n", "<leader>tb", gitsigns.toggle_current_line_blame, { desc = "[T]oggle git show [b]lame line" })
end

local M = {}

M.which_key_spec = {

	{ "<leader>c", group = "[C]ode", mode = { "n", "x" } },
	{ "<leader>d", group = "[D]ocument" },
	{ "<leader>h", group = "[H]arpoon" },
	{ "<leader>r", group = "[R]ename" },
	{ "<leader>f", group = "[F]ind" },
	{ "<leader>w", group = "[W]orkspace" },
	{ "<leader>t", group = "[T]oggle" },
	{ "<leader>g", group = "[G]it" },
	{ "<leader>s", group = "[S]plit" },
	{ "<leader>b", group = "[B]uffer" },
}

return M
