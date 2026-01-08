local M = {}

local function opt(key, default)
	key = "groob_" .. key
	if vim.g[key] == nil then
		return default
	end
	if vim.g[key] == 0 then
		return false
	end
	return vim.g[key]
end

M.config = {
	transparent = opt("transparent", true),
}

return M
