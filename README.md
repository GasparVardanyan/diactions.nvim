# diactions.nvim

Code actions based on diagnostics.

Sometimes LSP code actions are not enough. Linters like clang-tidy and cppcheck
provide useful diagnostics, but many of them do not have corresponding code
actions available in LSPs.

This plugin provides custom code actions based on diagnostic sources and codes.

Currently, none-ls is required because NeoVim already provides LSP code action
support. This plugin registers a custom none-ls source and exposes these code
actions through the LSP interface.

In the future, this plugin may support custom pickers (for example, fzf-lua),
making none-ls an optional dependency.

Currently, only a small number of clang-tidy and cppcheck code actions are
implemented. Since I use clang-tidy, cppcheck, and clazy in my C++ development,
I will regularly add new code actions utilizing these linters.

However, this plugin is not limited to C++ and can support diagnostics from
other languages and linters as well.

Contributions are welcome!

## Setup

The setup is straightforward:
```lua
return {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"GasparVardanyan/diactions.nvim",
	},
	config = function ()
		require("null-ls").setup ({
			sources = {
				require ("diactions.none-ls")
			}
		})
	end
}
```
