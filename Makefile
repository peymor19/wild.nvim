.PHONY: test

test:
	nvim --headless -c "set rtp+=../plenary.nvim" -c "PlenaryBustedDirectory lua/tests/"
