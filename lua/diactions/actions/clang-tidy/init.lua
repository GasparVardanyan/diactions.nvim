return function (params, diag, parser)
	local actions = {}

	local bufnr = params.bufnr

	local tree = parser:parse () [1]
	local root = tree:root ()

	local query = vim.treesitter.query.parse("cpp", [[
	(_) @node
	]])

	local modify_comment = function (comment, nolint)
		local text = vim.treesitter.get_node_text(comment, bufnr)

		local new_text

		local nolint_start, nolint_end, codes = text:find(nolint .. "%((.-)%)")

		if nolint_start then
			if not codes:match("(^|,)%s*" .. vim.pesc(diag.code) .. "%s*(,|$)") then
				new_text = text:sub(1, nolint_start + #nolint)
				.. codes
				.. ","
				.. diag.code
				.. text:sub(nolint_end)
			else
				new_text = text
			end
		else
			local block_start = "/*"
			local block_end = "*/"

			if text:sub(1, #block_start) == block_start then
				new_text = text:sub(1, -#block_end - 1)
				.. "; "
				.. nolint
				.. "("
				.. diag.code
				.. ") "
				.. block_end
			else
				new_text = text .. "; " .. nolint .. "(" .. diag.code .. ")"
			end
		end

		local sr, sc = comment:start()
		local er, ec = comment:end_()

		vim.api.nvim_buf_set_text(
			bufnr,
			sr,
			sc,
			er,
			ec,
			{ new_text }
		)
	end

	vim.list_extend (actions, {
		{
			title = "NOLINT " .. diag.code,
			action = function ()
				local comment

				for _, node in query:iter_captures(root, bufnr, diag.lnum, diag.lnum + 1) do
					if node:type() == "comment" then
						comment = node
					elseif comment then
						-- Found something after the comment, so it doesn't end the line.
						comment = nil
					end
				end

				if nil ~= comment
				then
					modify_comment (comment, "NOLINT")
				else
					local line = vim.api.nvim_buf_get_lines (bufnr, diag.lnum, diag.lnum + 1, false) [1]
					vim.api.nvim_buf_set_text (
						bufnr,
						diag.lnum,
						#line,
						diag.lnum,
						#line,
						{ "// NOLINT(" .. diag.code .. ")" }
					)
				end
			end
		},
		{
			title = "NOLINTNEXTLINE " .. diag.code,
			action = function ()
				local insert_line = diag.lnum
				local modified = false

				if diag.lnum > 0 then
					local prev_line = vim.api.nvim_buf_get_lines(
						bufnr,
						diag.lnum - 1,
						diag.lnum,
						false
					)[1]

					local comment

					for _, node in query:iter_captures(root, bufnr, diag.lnum - 1, diag.lnum) do
						if node:type() == "comment" then
							comment = node
						elseif comment then
							comment = nil
							break
						end
					end

					if comment then
						local _, sc, _, ec = comment:range()

						local before = prev_line:sub(1, sc)
						local after = prev_line:sub(ec + 1)

						if before:match("^%s*$") and after:match("^%s*$") then
							modify_comment (comment, "NOLINTNEXTLINE")
							modified = true
						end
					end
				end

				if false == modified
				then
					local diag_line = vim.api.nvim_buf_get_lines(
						bufnr,
						diag.lnum,
						diag.lnum + 1,
						false
					)[1]

					local indent = diag_line:match("^%s*") or ""

					vim.api.nvim_buf_set_lines(
						bufnr,
						insert_line,
						insert_line,
						false,
						{ indent .. "// NOLINTNEXTLINE(" .. diag.code .. ")" }
					)
				end
			end
		},
	})

	return actions
end
