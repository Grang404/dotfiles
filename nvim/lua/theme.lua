local function set_global_transparency_and_ui()
    local groups = {
        "Normal",
        "NormalNC",
        "NormalFloat",
        "SignColumn",
        "EndOfBuffer",
        "CursorLine",
    }

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
end

-- Set global transparency and customize UI initially
set_global_transparency_and_ui()

-- Ensure transparency and UI customization are maintained
vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    callback = set_global_transparency_and_ui,
})



