
-- lua/plugins/treesitter.lua
-- Used to highlight, edit, and navigate code
return {
  {
    "nvim-treesitter/nvim-treesitter",
    version = "main", -- same as specifying the branch
    config = function()
      -- Ensure basic parsers are installed
      local parsers = { "bash", "c", "diff", "html", "lua", "luadoc", "markdown", "markdown_inline", "query", "vim", "vimdoc" }
      require("nvim-treesitter").install(parsers)

      ---@param buf integer
      ---@param language string
      local function treesitter_try_attach(buf, language)
        -- Check if the buffer is valid (might not be after install completes)
        if not vim.api.nvim_buf_is_valid(buf) then return end

        -- Check if a parser exists and load it
        if not vim.treesitter.language.add(language) then return end

        -- Enable syntax highlighting and other treesitter features
        vim.treesitter.start(buf, language)

        -- Enable treesitter based folds
        -- vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        -- vim.wo.foldmethod = "expr"

        -- Enable treesitter based indentation if an indent query exists
        local has_indent_query = vim.treesitter.query.get(language, "indents") ~= nil
        if has_indent_query then
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end

      local available_parsers = require("nvim-treesitter").get_available()
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local buf, filetype = args.buf, args.match

          local language = vim.treesitter.language.get_lang(filetype)
          if not language then return end

          local installed_parsers = require("nvim-treesitter").get_installed("parsers")

          if vim.tbl_contains(installed_parsers, language) then
            -- Enable the parser if it is already installed
            treesitter_try_attach(buf, language)
          elseif vim.tbl_contains(available_parsers, language) then
            -- Auto-install available parsers and enable them when done
            require("nvim-treesitter").install(language):await(function()
              treesitter_try_attach(buf, language)
            end)
          else
            -- Parser exists but isn't managed by nvim-treesitter; try anyway
            treesitter_try_attach(buf, language)
          end
        end,
      })
    end,
  },
}
