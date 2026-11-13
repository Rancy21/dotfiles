do
	--- --------------------
	--- KEYMAPS ------------
	--- --------------------

	vim.keymap.set("n", "<leader>o", ":update<CR> :source<CR>")
	vim.keymap.set("n", "<leader>w", ":write<CR>", { desc = "Write file" })
	vim.keymap.set("n", "<leader>q", ":quit<CR>", { desc = "Quit neovim" })

	-- Hover on keword
	vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover)

	-- Buffer manipulation
	vim.keymap.set("n", "<leader>bn", ":bn<CR>", { desc = "Switch to next buffer" })
	vim.keymap.set("n", "<leader>bp", ":bp<CR>", { desc = "Switch to previous buffers" })

	-- Paste over visual selection without yanking the replaced text
	vim.keymap.set("x", "p", '"_dP', { noremap = true })
	vim.keymap.set("x", "P", '"_dP', { noremap = true })

	-- Disable highlight search
	vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

	vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format)

	-- resize splits with Ctrl+arrow keys
	vim.keymap.set("n", "<C-Up>", "<cmd>resize  +2<cr>")
	vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>")
	vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<cr>")
	vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<cr>")

	-- quick splits of the current buffer
	vim.keymap.set("n", "<leader>-", "<cmd>split<cr>", { desc = "Split below (Create a window below)" })
	vim.keymap.set("n", "<leader>|", "<cmd>vsplit<cr>", { desc = "Split right (Create a window on the right)" })

	-- toggle a terminal below
	vim.keymap.set("n", "<leader>tn", ":split | terminal<CR>i", { desc = "Toggle Terminal (below)" })

	-- Diagnostic Config & Keymaps
	--  See `:help vim.diagnostic.Opts`
	vim.diagnostic.config({
		update_in_insert = false,
		severity_sort = true,
		float = { border = "rounded", source = "if_many" },
		underline = { severity = { min = vim.diagnostic.severity.WARN } },

		-- Can switch between these as you prefer
		virtual_text = false, -- Text shows up at the end of the line
		virtual_lines = true, -- Text shows up underneath the line, with virtual lines

		-- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
		jump = {
			on_jump = function(_, bufnr)
				vim.diagnostic.open_float({
					bufnr = bufnr,
					scope = "cursor",
					focus = false,
				})
			end,
		},
	})

	vim.keymap.set("n", "<leader>dq", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

	-- Exit builtin terminal
	vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

	-- Keybinds to make split navigation easier.
	--  Use CTRL+<hjkl> to switch between windows
	--
	--  See `:help wincmd` for a list of all window commands
	vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
	vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
	vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
	vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })
end
