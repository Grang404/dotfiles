return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v2.x",
    requires = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
    },
    opts = {
      filesystem = {
        filtered_items = {
          hide_dotfiles = false, -- Show hidden files
          -- hide_gitignored = false, -- Optional: Show git ignored files
        },
      },
    },
  },
}
