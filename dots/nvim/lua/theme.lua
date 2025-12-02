vim.opt.runtimepath:append(vim.fn.stdpath("config") .. "/lua/themes/groob/colors")
require("themes.groob").colorscheme()

-- Function to set global transparency and UI elements
local function set_global_transparency_and_ui()
	local groups = {
		"Normal",
		"NormalNC",
		"NormalFloat",
		"SignColumn",
		"EndOfBuffer",
		"CursorLine",
	}
	-- Set transparency for various highlight groups
	for _, group in ipairs(groups) do
		vim.api.nvim_set_hl(0, group, { bg = "NONE", ctermbg = "NONE" })
	end
	-- Customize StatusLine and StatusLineNC
	vim.api.nvim_set_hl(0, "StatusLine", {
		fg = "#873c56",
		bg = "NONE",
		ctermfg = 223,
		ctermbg = "NONE",
	})
	vim.api.nvim_set_hl(0, "StatusLineNC", {
		fg = "#873c56",
		bg = "NONE",
		ctermfg = 223,
		ctermbg = "NONE",
	})
	vim.cmd([[
           highlight YankHighlight guibg=#F591B2 guifg=#C9C7CD ctermbg=magenta ctermfg=white
       ]])
	vim.api.nvim_set_hl(0, "Visual", { bg = "#57575F", fg = "#C9C7CD" })
	vim.api.nvim_set_hl(0, "CursorLine", { bg = "#11fcbd" })

	-- Jinja highlighting
	vim.api.nvim_set_hl(0, "@punctuation.special.htmldjango", { link = "Special" })
	vim.api.nvim_set_hl(0, "@keyword.htmldjango", { link = "Keyword" })
	vim.api.nvim_set_hl(0, "@variable.htmldjango", { link = "Identifier" })
	vim.api.nvim_set_hl(0, "@function.call.htmldjango", { link = "Function" })
	vim.api.nvim_set_hl(0, "@string.htmldjango", { link = "String" })
end

-- Single ColorScheme autocmd that does everything
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = set_global_transparency_and_ui,
})

-- Apply everything initially
set_global_transparency_and_ui()
