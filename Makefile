.PHONY: test

test:
	nvim --headless --noplugin -u NONE -c "set rtp+=../plenary.nvim" -c "PlenaryBustedDirectory lua/tests/"
