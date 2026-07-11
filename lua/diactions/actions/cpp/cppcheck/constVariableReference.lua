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
		title = "Make variable reference to const",
		action = function ()
			local n = node

			while n and n:type () ~= "declaration" do
				n = n:parent ()
			end

			if not n then
				return
			end

			local type_node

			for child in n:iter_children () do
				if child:type () == "init_declarator" then
					for reference_declarator in child:iter_children () do
						if reference_declarator:type () == "reference_declarator" then
							type_node = child
							break
						end
					end
				end
			end

			if not type_node
			then
				return
			end

			local row, col = type_node:start ()

			vim.api.nvim_buf_set_text (
				bufnr, row, col, row, col,
				{ "const " }
			)
		end
	})

	return actions
end
