
-- lua/plugins/lsp.lua
return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "mason-org/mason.nvim", config = true },
      "mason-org/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    config = function()
      -- [[ Servers to install and configure ]]
      -- Add/remove entries here; mason-tool-installer ensures they're installed.
      ---@type table<string, vim.lsp.Config>
      local servers = {
        stylua = {}, -- used to format Lua code

        -- Special Lua config, as recommended by neovim help docs
        lua_ls = {
          on_init = function(client)
            client.server_capabilities.documentFormattingProvider = false

            if client.workspace_folders then
              local path = client.workspace_folders[1].name
              if path ~= vim.fn.stdpath("config")
                and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
              then
                return
              end
            end

            local current_settings = client.config.settings --[[@as lspconfig.settings.lua_ls]]
            client.config.settings.Lua = vim.tbl_deep_extend("force", current_settings.Lua, {
              runtime = {
                version = "LuaJIT",
                path = { "lua/?.lua", "lua/?/init.lua" },
              },
              workspace = {
                checkThirdParty = false,
                -- NOTE: this is a lot slower and will cause issues when working on your own config
                library = vim.api.nvim_get_runtime_file("", true),
              },
            })
          end,
          ---@type lspconfig.settings.lua_ls
          settings = {
            Lua = {
              format = { enable = false }, -- formatting is done by stylua
            },
          },
        },

        -- Enable more servers by uncommenting/adding entries, e.g.:
        -- pyright = {},
        -- clangd = {},
        -- gopls = {},
        -- ts_ls = {},
        -- rust_analyzer = {},
      }

      -- [[ Mason setup ]]
      -- Translates between nvim-lspconfig server names and mason package names
      -- (e.g. lua_ls <-> lua-language-server)
      require("mason-lspconfig").setup({
        automatic_enable = false, -- set true to auto-enable servers installed manually via :Mason
      })

      -- Ensure the servers (and any extra tools) are installed
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        -- add other tools here, e.g. "prettier", "ruff", ...
      })
      require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

      -- [[ Register and enable each server via Neovim's built-in LSP API ]]
      for name, server in pairs(servers) do
        vim.lsp.config(name, server)
        vim.lsp.enable(name)
      end
    end,
  },
}
