return {
	"terrortylor/nvim-comment",
	dependencies = "JoosepAlviste/nvim-ts-context-commentstring",
	config = function()
		require("nvim_comment").setup({
			create_mappings = false,
			hook = function()
				if vim.api.nvim_buf_get_option(0, "filetype") == "vue" then
					vim.api.nvim_buf_set_option(0, "commentstring", "<!-- %s -->") -- hack for now
					-- require("ts_context_commentstring.internal").update_commentstring() -- this should work, but it doesnt. god damn
				end
			end,
		})
	end,
}
