for _, a in ipairs(vim.api.nvim_get_autocmds({ group = "kickstart-highlight-yank" })) do
	print(vim.inspect(a))
end
