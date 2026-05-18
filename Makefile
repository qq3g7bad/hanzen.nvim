.PHONY: test lint fmt deps

PLENARY := .deps/plenary.nvim

deps: $(PLENARY)

$(PLENARY):
	git clone --depth 1 https://github.com/nvim-lua/plenary.nvim $(PLENARY)

test: deps
	nvim --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }"

lint:
	stylua --check lua plugin tests

fmt:
	stylua lua plugin tests
