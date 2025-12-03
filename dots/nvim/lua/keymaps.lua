-- ============================================================================
-- GENERAL KEYMAPS
-- ============================================================================

-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- ============================================================================
-- WINDOW MANAGEMENT
-- ============================================================================

-- Vertical split
vim.keymap.set("n", "<leader>vs", ":vsplit<CR>", { desc = "Open vertical split" })

-- Window navigation
vim.keymap.set("n", "<A-j>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<A-k>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<A-h>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<A-l>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- Close buffer and return to directory
vim.keymap.set("n", "<leader>wq", ":bd<CR>:e .<CR>", { desc = "Quit to directory list" })

-- ============================================================================
-- TERMINAL
-- ============================================================================

vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- ============================================================================
-- DIAGNOSTICS
-- ============================================================================

vim.keymap.set("n", "<leader>cq", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- ============================================================================
-- TELESCOPE (set in setup_telescope_keymaps function)
-- ============================================================================

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
	vim.keymap.set("n", "<leader>f.", builtin.oldfiles, { desc = '[F]ind Recent Files ("." for repeat)' })
	vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })

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

-- ============================================================================
-- COLORIZER
-- ============================================================================

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

	vim.keymap.set("n", "<leader>tc", toggle_colorizer, { desc = "Toggle colorizer" })
end

-- ============================================================================
-- LSP (set when LSP attaches to buffer)
-- ============================================================================

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
	map("<leader>td", _G.toggle_diagnostics, "[T]oggle [D]iagnostics")
	map("<leader>hd", _G.toggle_hover_diagnostics, "[H]ide [D]iagnostics")
	map("<leader>de", _G.show_only_errors_and_warnings, "[D]iagnostics [E]rrors Only")
	map("<leader>e", vim.diagnostic.open_float, "Show line diagnostics")

	-- Inlay hints toggle
	local client = vim.lsp.get_client_by_id(event.data.client_id)
	if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
		map("<leader>th", function()
			vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
		end, "[T]oggle Inlay [H]ints")
	end
end

-- ============================================================================
-- CONFORM (Formatting)
-- ============================================================================

function setup_conform_keymaps()
	vim.keymap.set("", "<leader>F", function()
		require("conform").format({ async = true, lsp_format = "fallback" })
	end, { desc = "[F]ormat buffer" })
end

-- ============================================================================
-- HARPOON
-- ============================================================================

function setup_harpoon_keymaps()
	vim.keymap.set("n", "<leader>ha", ':lua require("harpoon.mark").add_file()<CR>', { desc = "[A]dd file to Harpoon" })
	vim.keymap.set("n", "<leader>hq", ':lua require("harpoon.ui").toggle_quick_menu()<CR>', { desc = "[Q]uick Menu" })

	-- Navigate to files 0-9
	for i = 0, 9 do
		vim.keymap.set(
			"n",
			"<leader>h" .. i,
			':lua require("harpoon.ui").nav_file(' .. i .. ")<CR>",
			{ desc = "Navigate to file " .. i }
		)
	end
end

-- ============================================================================
-- GITSIGNS (set when gitsigns attaches to buffer)
-- ============================================================================

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
