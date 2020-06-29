PARTS=$(sort $(wildcard parts/*.sh))
TMP := $(shell mktemp)

help:
	@egrep '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'

all: gxadmin test docs ## Do everything, build, run tests, build docs.

docs: ## Build documentation for gxadmin
	@cat $(PARTS) > .tmpgxadmin
	@chmod +x .tmpgxadmin
	./.tmpgxadmin meta cmdlist
	@rm -f .tmpgxadmin

gxadmin: $(PARTS) ## Build the gxadmin executable
	cat $(PARTS) > gxadmin
	chmod +x gxadmin

test: ## Run the test suite
	@cat $(PARTS) > .tmpgxadmin
	@chmod +x .tmpgxadmin
	./test.sh
	@rm -f .tmpgxadmin

shellcheck: gxadmin ## Run shellcheck (optional)
	@# SC2001 - stylistic, no thank you!
	@# SC2119 - literally no clue
	@# SC2120 - literally no clue
	@# SC2129 - stylistic, maybe should switch to
	shellcheck -s bash -f gcc --exclude SC2001,SC2120,SC2119,SC2129,SC2044 gxadmin
	shellcheck -s bash -f gcc --exclude SC2001,SC2120,SC2119,SC2129,SC2044 gxadmin-complete.sh

shellcheck-parts: ## Run shellcheck, split version (optional)
	@# SC2001 - stylistic, no thank you!
	@# SC2119 - literally no clue
	@# SC2120 - literally no clue
	@# SC2129 - stylistic, maybe should switch to
	@# SC2154 - unnecessary due to split
	@# SC2034 - unnecessary due to split
	shellcheck -s bash -f gcc --exclude SC2001,SC2120,SC2119,SC2129,SC2044,SC2154,SC2034 parts/[023456789]*

.PHONY: test shellcheck shellcheck-parts docs help
