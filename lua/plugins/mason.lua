-- Customize Mason

---@type LazySpec
return {
  -- use mason-tool-installer for automatically installing Mason packages
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    -- overrides `require("mason-tool-installer").setup(...)`
    opts = {
      -- Make sure to use the names found in `:Mason`
      ensure_installed = {
        -- Language Servers
        "lua-language-server",
        "typescript-language-server",
        "clangd",
        "css-lsp",
        "svelte-language-server",
        "docker-compose-language-service",
        "neocmakelsp",
        "cmake-language-server",

        -- Formatters
        "prettier",
        "black",
        "clang-format",
        "stylua",

        -- Linters
        "checkmake",

        -- Debuggers
        "debugpy",
      },
      auto_update = false,
      run_on_start = true,
      start_delay = 3000,
    },
  },
}
