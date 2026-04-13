-- Clear search highlights
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Vertical split
vim.keymap.set("n", "<leader>sv", ":vsplit<CR>", { desc = "[S]plit [V]ertical" })

-- Window navigation
vim.keymap.set("n", "<A-j>", "<C-w><C-h>", { desc = "Window left" })
vim.keymap.set("n", "<A-k>", "<C-w><C-l>", { desc = "Window right" })
vim.keymap.set("n", "<A-h>", "<C-w><C-j>", { desc = "Window down" })
vim.keymap.set("n", "<A-l>", "<C-w><C-k>", { desc = "Window up" })

-- Buffer
vim.keymap.set("n", "<leader>wq", ":bd<CR>:e .<CR>", { desc = "Quit to directory" })
vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "[B]uffer [N]ext" })
vim.keymap.set("n", "<leader>bp", ":bprevious<CR>", { desc = "[B]uffer [P]revious" })

-- Terminal
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Toggle: format on save
vim.keymap.set("n", "<leader>tf", function()
	vim.g.format_on_save = not vim.g.format_on_save
	vim.notify("Format on save: " .. (vim.g.format_on_save and "enabled" or "disabled"))
end, { desc = "[T]oggle [F]ormat on save" })

-- Toggle: colorizer
vim.g.colorizer_enabled = true
vim.keymap.set("n", "<leader>tc", function()
	vim.g.colorizer_enabled = not vim.g.colorizer_enabled
	vim.cmd(vim.g.colorizer_enabled and "HighlightColors On" or "HighlightColors Off")
	vim.notify("Colorizer: " .. (vim.g.colorizer_enabled and "enabled" or "disabled"))
end, { desc = "[T]oggle [C]olorizer" })

-- Toggle: diagnostics
vim.g.diagnostics_enabled = true
vim.keymap.set("n", "<leader>td", function()
	vim.g.diagnostics_enabled = not vim.g.diagnostics_enabled
	vim.diagnostic.enable(vim.g.diagnostics_enabled)
	vim.notify("Diagnostics: " .. (vim.g.diagnostics_enabled and "enabled" or "disabled"))
end, { desc = "[T]oggle [D]iagnostics" })

------------------------------------------------------------------------
-- TELESCOPE
------------------------------------------------------------------------

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
	vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "[F]ind [B]uffers" })
	vim.keymap.set("n", "<leader>fo", builtin.oldfiles, { desc = "[F]ind [O]ld files" })
	vim.keymap.set("n", "<leader>fn", function()
		builtin.find_files({ cwd = vim.fn.stdpath("config") })
	end, { desc = "[F]ind [N]eovim config" })

	vim.keymap.set("n", "<leader>/", function()
		builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
			winblend = 10,
			previewer = false,
		}))
	end, { desc = "[/] Fuzzy search buffer" })

	vim.keymap.set("n", "<leader>f/", function()
		builtin.live_grep({ grep_open_files = true, prompt_title = "Live Grep in Open Files" })
	end, { desc = "[F]ind [/] in open files" })
end

------------------------------------------------------------------------
-- LSP
------------------------------------------------------------------------

function setup_lsp_keymaps(event)
	local map = function(keys, func, desc, mode)
		vim.keymap.set(mode or "n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
	end
	local builtin = require("telescope.builtin")

	-- Navigation
	map("gd", builtin.lsp_definitions, "[G]oto [D]efinition")
	map("gr", builtin.lsp_references, "[G]oto [R]eferences")
	map("gI", builtin.lsp_implementations, "[G]oto [I]mplementation")
	map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
	map("<leader>D", builtin.lsp_type_definitions, "Type [D]efinition")

	-- Symbols
	map("<leader>ds", builtin.lsp_document_symbols, "[D]ocument [S]ymbols")
	map("<leader>ws", builtin.lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

	-- Actions
	map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
	map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })

	-- Diagnostics
	map("<leader>cq", vim.diagnostic.setloclist, "[C]ode [Q]uickfix list")
	map("<leader>cd", vim.diagnostic.open_float, "[C]ode [D]iagnostics float")
	map("<leader>ce", function()
		local diags = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
		if #diags > 0 then
			vim.fn.setreg("+", diags[1].message)
			vim.notify("Yanked diagnostic")
		else
			vim.notify("No diagnostic on line", vim.log.levels.WARN)
		end
	end, "[C]ode [E]rror yank")

	-- Toggle: inlay hints (LSP capability check)
	local client = vim.lsp.get_client_by_id(event.data.client_id)
	if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
		map("<leader>ti", function()
			vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
		end, "[T]oggle [I]nlay hints")
	end
end

------------------------------------------------------------------------
-- GITSIGNS
------------------------------------------------------------------------

function setup_gitsigns_keymaps(bufnr)
	local gs = require("gitsigns")
	local function map(mode, l, r, opts)
		vim.keymap.set(mode, l, r, vim.tbl_extend("force", { buffer = bufnr }, opts or {}))
	end

	-- Navigation
	map("n", "]c", function()
		if vim.wo.diff then
			vim.cmd.normal({ "]c", bang = true })
		else
			gs.nav_hunk("next")
		end
	end, { desc = "Next git [c]hange" })

	map("n", "[c", function()
		if vim.wo.diff then
			vim.cmd.normal({ "[c", bang = true })
		else
			gs.nav_hunk("prev")
		end
	end, { desc = "Prev git [c]hange" })

	-- Hunks
	map("n", "<leader>gs", gs.stage_hunk, { desc = "[G]it [S]tage hunk" })
	map("n", "<leader>gr", gs.reset_hunk, { desc = "[G]it [R]eset hunk" })
	map("n", "<leader>gS", gs.stage_buffer, { desc = "[G]it [S]tage buffer" })
	map("n", "<leader>gR", gs.reset_buffer, { desc = "[G]it [R]eset buffer" })
	map("n", "<leader>gp", gs.preview_hunk, { desc = "[G]it [P]review hunk" })
	map("n", "<leader>gd", gs.diffthis, { desc = "[G]it [D]iff index" })
	map("n", "<leader>gD", function()
		gs.diffthis("@")
	end, { desc = "[G]it [D]iff last commit" })
	map("n", "<leader>gb", gs.blame_line, { desc = "[G]it [B]lame line" })

	map("v", "<leader>gs", function()
		gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
	end, { desc = "[G]it [S]tage hunk" })

	map("v", "<leader>gr", function()
		gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
	end, { desc = "[G]it [R]eset hunk" })

	-- Toggle: git blame (per-buffer, lives here)
	map("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "[T]oggle git [B]lame" })
end

------------------------------------------------------------------------
-- HARPOON (v2)
------------------------------------------------------------------------

function setup_harpoon_keymaps()
	local harpoon = require("harpoon")
	harpoon:setup()

	vim.keymap.set("n", "<leader>a", function()
		harpoon:list():add()
	end, { desc = "Harpoon add" })
	vim.keymap.set("n", "<leader>q", function()
		harpoon.ui:toggle_quick_menu(harpoon:list())
	end, { desc = "Harpoon menu" })
	vim.keymap.set("n", "<leader>n", function()
		harpoon:list():next()
	end, { desc = "Harpoon next" })
	vim.keymap.set("n", "<leader>p", function()
		harpoon:list():prev()
	end, { desc = "Harpoon prev" })
	for i = 1, 9 do
		vim.keymap.set("n", "<leader>" .. i, function()
			harpoon:list():select(i)
		end, { desc = "Harpoon file " .. i })
	end
end

------------------------------------------------------------------------
-- COLORIZER (stub — setup_colorizer_keymaps kept for lazy.lua compat)
------------------------------------------------------------------------

function setup_colorizer_keymaps()
	-- Keymap is defined globally above; this is a no-op kept for API compat.
end

------------------------------------------------------------------------
-- WHICH-KEY SPEC
------------------------------------------------------------------------

local M = {}

M.which_key_spec = {
	{ "<leader>c", group = "[C]ode", mode = { "n", "x" } },
	{ "<leader>d", group = "[D]ocument" },
	{ "<leader>f", group = "[F]ind" },
	{ "<leader>g", group = "[G]it" },
	{ "<leader>r", group = "[R]ename" },
	{ "<leader>s", group = "[S]plit" },
	{ "<leader>b", group = "[B]uffer" },
	{ "<leader>t", group = "[T]oggle" },
	{ "<leader>w", group = "[W]orkspace" },
	{ "<leader>a", hidden = true },
	{ "<leader>q", hidden = true },
	{ "<leader>n", hidden = true },
	{ "<leader>p", hidden = true },
	{ "<leader>1", hidden = true },
	{ "<leader>2", hidden = true },
	{ "<leader>3", hidden = true },
	{ "<leader>4", hidden = true },
	{ "<leader>5", hidden = true },
	{ "<leader>6", hidden = true },
	{ "<leader>7", hidden = true },
	{ "<leader>8", hidden = true },
	{ "<leader>9", hidden = true },
}

return M
