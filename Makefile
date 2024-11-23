.PHONY: test

test:
	nvim --headless --noplugin -u scripts/wild_test_init.vim -c "PlenaryBustedDirectory lua/tests/"
