return function(params, diag, parser)
	local actions = {}
	local bufnr = params.bufnr
	local tree = parser:parse()[1]
	local root = tree:root()

	local node = root:named_descendant_for_range(
		diag.lnum, diag.col, diag.lnum, diag.col
	)

	table.insert(actions, {
		title = "Pass argument by value",

		action = function()
			while node and node:type() ~= "parameter_declaration" do
				node = node:parent()
			end
			if not node then return end

			local removals = {}

			for child in node:iter_children() do
				if child:type() == "type_qualifier" then
					local text = vim.treesitter.get_node_text(child, bufnr)
					if text == "const" then
						table.insert(removals, child)
					end
				end
			end

			for child in node:iter_children() do
				if child:type() == "reference_declarator" then
					for ref_child in child:iter_children() do
						local text = vim.treesitter.get_node_text(ref_child, bufnr)
						if ref_child:type() == "&" or text == "&" then
							table.insert(removals, ref_child)
							break
						end
					end
				end
			end

			table.sort(removals, function(a, b)
				local _, ac = a:start()
				local _, bc = b:start()
				return ac > bc
			end)

			-- TODO: polish whitespace around the removals

			for _, n in ipairs(removals) do
				local sr, sc = n:start()
				local er, ec = n:end_()
				local line = vim.api.nvim_buf_get_lines(bufnr, sr, sr+1, false)[1] or ""

				while sc > 0 and line:sub(sc, sc):match("%s") do
					sc = sc - 1
				end

				while ec < #line and line:sub(ec+1, ec+1):match("%s") do
					ec = ec + 1
				end

				vim.api.nvim_buf_set_text(bufnr, sr, sc, er, ec, {" "})
			end
		end,
	})

	return actions
end
