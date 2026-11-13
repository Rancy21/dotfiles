return {
	{
		"akinsho/bufferline.nvim",
		version = "*",
		dependencies = "nvim-tree/nvim-web-devicons",
		config = function()
			require("bufferline").setup({
				options = {
					-- show a close button on each tab
					close_command = "bdelete! %d",
					right_mouse_command = "bdelete! %d",

					--diagnostics from your lsp appear on the tab
					diagnostics = "nvim_lsp",

					--show buffer numbers so you can jump with :b<n>
					numbers = "ordinal",

					-- let buffers span the full width
					offsets = {
						{
							filetype = "neo-tree", -- if you ever add a file tree
							text = "Explorer",
							highlight = "Directory",
						},
					},
				},
			})

			-- keymaps to move between buffers using the tab line position
			vim.keymap.set("n", "<Tab>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
			vim.keymap.set("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
			vim.keymap.set("n", "<leader>bp", "<cmd>BufferLinePick<CR>", { desc = "[B]uffer [P]ick" })
			vim.keymap.set("n", "<leader>bc", "<cmd>BufferLinePickClose<CR>", { desc = "[B]uffer [C]lose (pick)" })
			vim.keymap.set("n", "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", { desc = "Close all other buffers" })
		end,
	},
}
