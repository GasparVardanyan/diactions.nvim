return function (params, diag, parser)
	local actions = {}

	local bufnr = params.bufnr

	table.insert (actions, {
		title = "Fix the closing comment",
		action = function ()
			if diag.message:match ("^[aA]nonymous namespace not terminated with a closing comment")
			then
				local tree = parser:parse () [1]
				local root = tree:root ()

				local node = root:named_descendant_for_range (
					diag.lnum,
					diag.col,
					diag.lnum,
					diag.col
				)

				local row, col = node:end_ ()
				vim.api.nvim_buf_set_text (
					bufnr,
					row,
					col,
					row,
					col,
					{ " // end anonymous namespace" }
				)
			elseif diag.message:match ("^[aA]nonymous namespace ends with an unrecognized comment")
				or diag.message:match ("^[aA]nonymous namespace ends with a comment that refers to a wrong namespace.*")
			then
				local line = vim.api.nvim_buf_get_lines (bufnr, diag.lnum, diag.lnum + 1, false) [1]

				vim.api.nvim_buf_set_text (
					bufnr,
					diag.lnum,
					diag.col,
					diag.lnum,
					#line,
					{ " // end anonymous namespace" }
				)
			else
				local ns = diag.message:match (
					"^[nN]amespace '([^']+)' not terminated with a closing comment"
				)

				if nil ~= ns
				then
					local tree = parser:parse () [1]
					local root = tree:root ()

					local node = root:named_descendant_for_range (
						diag.lnum,
						diag.col,
						diag.lnum,
						diag.col
					)

					local row, col = node:end_ ()
					vim.api.nvim_buf_set_text (
						bufnr,
						row,
						col,
						row,
						col,
						{ " // end namespace " .. ns }
					)
				else
					ns = diag.message:match (
						"^[nN]amespace '([^']+)' ends with an unrecognized comment"
					)

					if nil == ns
					then
						ns = diag.message:match (
							"^[nN]amespace '([^']+)' ends with a comment that refers to a wrong namespace.*"
						)
					end

					if nil ~= ns
					then
						local line = vim.api.nvim_buf_get_lines (bufnr, diag.lnum, diag.lnum + 1, false)[1]

						vim.api.nvim_buf_set_text (
							bufnr,
							diag.lnum,
							diag.col,
							diag.lnum,
							#line,
							{ " // end namespace " .. ns }
						)
					end
				end
			end

		end
	})

	return actions
end
