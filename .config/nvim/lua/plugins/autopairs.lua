--  typing { gives {} with the cursor inside, " gives "", same for (), [], `
return {
	{
		"echasnovski/mini.pairs",
		version = "*",
		config = function()
			require("mini.pairs").setup()
		end,
	},
}
