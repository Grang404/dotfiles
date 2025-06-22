vim.opt.runtimepath:append(vim.fn.stdpath("config") .. "/lua/themes/mellow/colors")

require("themes.mellow").colorscheme()

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
		fg = "#ea83a5",
		bg = "NONE",
		ctermfg = 223,
		ctermbg = "NONE",
	})
	vim.api.nvim_set_hl(0, "StatusLineNC", {
		fg = "#ea83a5",
		bg = "NONE",
		ctermfg = 223,
		ctermbg = "NONE",
	})

	-- vim.api.nvim_set_hl(0, "Normal", { bg = "NONE", ctermbg = "NONE" })
	-- vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE", ctermbg = "NONE" })
	vim.cmd([[
	           highlight YankHighlight guibg=#F591B2 guifg=#C9C7CD ctermbg=magenta ctermfg=white
	       ]])
	vim.api.nvim_set_hl(0, "Visual", { bg = "#57575F", fg = "#C9C7CD" })
	vim.api.nvim_set_hl(0, "CursorLine", { bg = "#11fcbd" })
end

-- Set global transparency and customize UI elements
set_global_transparency_and_ui()

-- Ensure transparency and UI customization are maintained after ColorScheme changes
vim.api.nvim_create_autocmd({ "ColorScheme" }, {
	callback = set_global_transparency_and_ui,
})
