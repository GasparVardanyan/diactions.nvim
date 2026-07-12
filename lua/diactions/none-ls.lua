local function get_actions (params, diag)
	local actions = {}

	local bufnr = params.bufnr
	local ft = params.ft

	local parser = vim.treesitter.get_parser (bufnr, ft)
	if nil == parser
	then
		vim.print ('No treesitter parser available')
		return {}
	end

	for _, code in ipairs(vim.split(diag.code, ",", { plain = true })) do
		local module = table.concat ({"diactions.actions", diag.source, code}, ".")

		local found, action = pcall (require, module)

		if true == found
		then
			vim.list_extend (actions, action (params, diag, parser))
		end
	end

	return actions
end

return {
	name = "diactions.nvim",
	method = require ("null-ls").methods.CODE_ACTION,
	filetypes = { "cpp" },
	generator = {
		async = false,
		fn = function (params)
			local diagnostics = vim.diagnostic.get (params.bufnr, {
				lnum = params.lsp_params.range.start.line,
			})

			local actions = {}

			for _, diag in ipairs (diagnostics) do
				vim.list_extend (actions, get_actions (params, diag))
			end

			return actions
		end,
	},
}
