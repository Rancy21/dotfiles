-- -----------------------
-- VIM GENERAL CONFIG ----
-- -----------------------
vim.cmd.colorscheme "catppuccin"
vim.opt.number = true
vim.o.relativenumber = true
vim.o.wrap = false
vim.o.tabstop = 4
vim.o.swapfile = false
vim.g.mapleader = " " -- set <Space> as the leader key
vim.o.winborder = "rounded"
vim.opt.clipboard = "unnamedplus"

--- --------------------
--- KEYMAPS ------------
--- --------------------

vim.keymap.set('n', '<leader>o', ':update<CR> :source<CR>')
vim.keymap.set('n', '<leader>w', ':write<CR>')
vim.keymap.set('n', '<leader>q', ':quit<CR>')

-- Hover on keword
vim.keymap.set('n', '<leader>k', vim.lsp.buf.hover)

-- Paste over visual selection without yanking the replaced text
vim.keymap.set('x', 'p', '"_dP', { noremap = true })
vim.keymap.set('x', 'P', '"_dP', { noremap = true })

-- Disable highlight search
vim.keymap.set('n', '<leader>nh', ':noh<CR>', { noremap = true })

vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format)

vim.keymap.set('n', '<leader>f', ':Pick files<CR>')
vim.keymap.set('n', '<leader>h', ':Pick help<CR>')

vim.keymap.set('n', '<leader>e', ':Oil<CR>')

----------------
--- PLUGINS ----
----------------

-- JAVA
vim.pack.add({
	{
		src = 'https://github.com/JavaHello/spring-boot.nvim',
		version = '218c0c26c14d99feca778e4d13f5ec3e8b1b60f0',
	},
	'https://github.com/MunifTanjim/nui.nvim',
	'https://github.com/mfussenegger/nvim-dap',

	'https://github.com/nvim-java/nvim-java',
})



vim.pack.add({
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/echasnovski/mini.pick" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" }
})
require "nvim-treesitter".setup({
	ensure_installed = { "lua", "java", "go" },
	highlight = { enabled = true }
})
require "mason".setup()
require "mini.pick".setup()
require "oil".setup()




-- customize gopls settings
vim.lsp.config('gopls', {
	settings = {
		gopls = {
			analyses = {
				unusedparams = true,
				shadow = true,
			},
			staticcheck = true,
			gofumpt = true,
			usePlaceholders = true,
			hints = {
				assignVariableTypes = true,
				compositeLiteralFields = true,
				compositeLiteralTypes = true,
				constantValues = true,
				functionTypeParameters = true,
				parameterNames = true,
				rangeVariableTypes = true,
			},
		},
	},
})



-- auto complete
--
-- vim.api.nvim_create_autocmd('LspAttach', {
-- 		callback = function(ev)
-- 				local client = vim.lsp.get_client_by_id(ev.data.client_id)
-- 				if client:supports_method('textDocument/completion') then
-- 						vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
-- 				end
-- 		end,
-- })
-- vim.cmd("set completeopt+=noselect")


--- ==========================================
--- SETTING UP AUTOCOMPLETE AND FORMAT ON SAVE
--- ==========================================

vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('GlobalLsp', { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		local buf = args.buf

		-- Format + Organize imports on save
		vim.api.nvim_create_autocmd('BufWritePre', {
			group = vim.api.nvim_create_augroup('LspSave_' .. buf, { clear = true }),
			buffer = buf,
			callback = function()
				-- Organize Imports first (silently skip if server does not support it)
				if client and client:supports_method('textDocument/codeAction') then
					pcall(vim.lsp.buf.code_action, {
						context = { only = { 'source.organizeImports' } },
						apply = true,
					})
				end

				-- Format via this specific client only(avoids duplilcate formatters)
				vim.lsp.buf.format({ async = false, id = client.id })
			end,
		})
	end,
})
-- vim.cmd("set completeopt+=noselect")
-- ============================================================
-- Install blink.cmp + friendly-snippets
-- ============================================================
vim.pack.add({
	{ src = "https://github.com/saghen/blink.cmp",             version = vim.version.range("^1") },
	{ src = "https://github.com/rafamadriz/friendly-snippets", },
})

--- Configure blink.cmp
require("blink.cmp").setup({
	keymap = { preset = "super-tab" },
	appearance = {
		nerd_font_variant = "mono",
		use_nvim_cmp_as_default = true,
	},
	completion = {
		documentation = {
			auto_show = true,
			auto_show_delay_ms = 200,
		},

		ghost_text = { enabled = true },
		menu = {
			draw = {
				treesitter = { "lsp" },
			},
		},
	},

	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
	},

	snippets = { preset = "default" },

	cmdline = {
		enabled = true,
		keymap = { preset = "cmdline" },
		completion = {
			menu = { auto_show = true },
			list = { selection = { preselect = false } },
		},
	},

	signature = { enabled = true },
	fuzzy = { implementation = "prefer_rust_with_warning" },
})

--- ============================================================
-- ADD AND/OR ENABLE LANGUAGE SERVERS
--- ============================================================
vim.lsp.enable('gopls')
vim.lsp.enable({ "lua_ls", "pyright" })
