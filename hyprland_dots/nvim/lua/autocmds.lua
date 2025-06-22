vim.api.nvim_create_user_command("InspectHighlight", function()
	local cursorline_hl = vim.api.nvim_get_hl(0, { name = "CursorLine" })
	print(vim.inspect(cursorline_hl))
end, {})

-- Highlight when yanking text
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank({ higroup = "YankHighlight" })
	end,
})

-- Remove auto comment on new line
vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- Dunno why but I need to do all this for it to actually work hehe -- probably the colorscheme

vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter", "BufEnter" }, {
	callback = function()
		vim.schedule(function()
			-- Enable cursorline
			vim.opt.cursorline = true

			-- Force the highlight
			vim.api.nvim_set_hl(0, "CursorLine", {
				bg = "#3e3e43",
				fg = "NONE",
				bold = false,
				default = false,
				force = true,
			})
		end)
	end,
})
