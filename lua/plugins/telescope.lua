return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim", -- required
    "nvim-telescope/telescope-fzf-native.nvim", -- optional, fast sorting
  },
  opts = {
    defaults = {
      layout_strategy = "horizontal",
      layout_config = { prompt_position = "top" },
      sorting_strategy = "ascending",
      winblend = 10,
    },
    pickers = {
      find_files = { hidden = true },
    },
    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = "smart_case",
      },
    },
  },
  config = function(_, opts)
    local telescope = require "telescope"
    telescope.setup(opts)
    pcall(telescope.load_extension, "fzf")

    -- Example custom mapping
    vim.keymap.set("n", "<leader>km", "<cmd>Telescope keymaps<cr>", { desc = "Search keymaps" })
  end,
}
