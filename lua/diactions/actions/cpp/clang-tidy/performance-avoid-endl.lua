return function (params, diag, parser)
	local actions = {}

	local bufnr = params.bufnr

	local tree = parser:parse () [1]
	local root = tree:root ()

	local node = root:named_descendant_for_range (
		diag.lnum,
		diag.col,
		diag.lnum,
		diag.col
	)

	table.insert (actions, {
		title = "Replace endl with \n",
		action = function ()
			node = node:parent()
			local outer_expr = node:parent()

			local replaced = false

			if outer_expr and outer_expr:type() == "binary_expression" then
				local prev = outer_expr:field("left")[1]
				if prev then

					while prev:type() == "binary_expression" do
						local right = prev:field("right")[1]
						if right then prev = right else break end
					end

					if prev:type() == "string_literal" then
						local lit_er, lit_ec = prev:end_()
						local start_row, start_col = lit_er, lit_ec - 1
						local _, end_col = node:end_()
						vim.api.nvim_buf_set_text(bufnr, start_row, start_col, lit_er, end_col, {"\\n\""})
						replaced = true
					end
				end
			end

			if not replaced then
				local sr, sc, er, ec = node:range()
				vim.api.nvim_buf_set_text(bufnr, sr, sc, er, ec, {"'\\n'"})
			end
		end
	})

	return actions
end
