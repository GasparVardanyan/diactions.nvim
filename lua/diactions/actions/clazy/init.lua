return function (params, diag, parser)
	diag.code = diag.code:gsub ("[^,]+", "clazy-%0")
	return require ("diactions.actions.clang-tidy") (params, diag, parser)
end
