vim.api.nvim_create_user_command("InspectHighlight", function()
	local cursorline_hl = vim.api.nvim_get_hl(0, { name = "CursorLine" })
	print(vim.inspect(cursorline_hl))
end, {})

-- Highlight when yanking text
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank({ higroup = "YankHighlight" })
	end,
})

-- Remove auto comment on new line
vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})
