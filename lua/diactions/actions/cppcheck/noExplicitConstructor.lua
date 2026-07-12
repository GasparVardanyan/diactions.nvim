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
		title = "Make constructor explicit",
		action = function ()
			local n = node

			while n and n:type () ~= "function_declarator" do
				n = n:parent ()
			end

			if not n then
				return
			end

			local identifier_node

			for child in n:iter_children ()
			do
				local t = child:type ()
				if t == "identifier"
				then
					identifier_node = child
					break
				end
			end

			if not identifier_node
			then
				return
			end


			local row, col = identifier_node:start ()

			vim.api.nvim_buf_set_text (
				bufnr, row, col, row, col,
				{ "explicit " }
			)
		end
	})

	return actions
end
