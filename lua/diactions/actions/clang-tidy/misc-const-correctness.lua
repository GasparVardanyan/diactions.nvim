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
		title = "Make variable const",
		action = function ()
			while node and node:type () ~= "declaration" do
				node = node:parent ()
			end

			if not node then
				return
			end

			local type_node

			for child in node:iter_children () do
				local t = child:type ()
				if
					t == "primitive_type"
					or t == "type_identifier"
					or t == "qualified_identifier"
					or t == "placeholder_type_specifier"
				then
					type_node = child
					break
				end
			end

			if not type_node
			then
				return
			end

			local row, col = type_node:start ()

			vim.api.nvim_buf_set_text(
				bufnr, row, col, row, col,
				{ "const " }
			)
		end
	})

	return actions
end
