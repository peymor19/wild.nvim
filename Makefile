.PHONY: test

test:
	nvim --headless -u scripts/wild_test_init.vim -c "PlenaryBustedDirectory lua/tests/"
