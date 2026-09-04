PARTS=$(sort $(wildcard parts/*.sh))
TMP := $(shell mktemp)

.DEFAULT_GOAL := help

help: ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_.-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

all: gxadmin test docs ## Build gxadmin, run tests, and regenerate docs

docs: ## Regenerate the docs/README.*.md command reference
	@cat $(PARTS) > .tmpgxadmin
	@chmod +x .tmpgxadmin
	./.tmpgxadmin meta cmdlist
	@rm -f .tmpgxadmin

gxadmin: $(PARTS) ## Assemble the gxadmin script from parts/*.sh
	cat $(PARTS) > gxadmin
	chmod +x gxadmin

test: ## Run shellcheck and the bats test suite
	shellcheck --exclude SC2148 parts/22-query.sh
	@cat $(PARTS) > .tmpgxadmin
	@chmod +x .tmpgxadmin
	./test.sh
	shellcheck --severity error .tmpgxadmin
	@rm -f .tmpgxadmin

shellcheck: gxadmin ## Run shellcheck on the assembled gxadmin script
	@# SC2001 - stylistic, no thank you!
	@# SC2119 - literally no clue
	@# SC2120 - literally no clue
	@# SC2129 - stylistic, maybe should switch to
	shellcheck -s bash -f gcc --exclude SC2001,SC2120,SC2119,SC2129,SC2044 gxadmin
	shellcheck -s bash -f gcc --exclude SC2001,SC2120,SC2119,SC2129,SC2044 gxadmin-complete.sh

shellcheck-parts: ## Run shellcheck on the individual parts/*.sh files
	@# SC2001 - stylistic, no thank you!
	@# SC2119 - literally no clue
	@# SC2120 - literally no clue
	@# SC2129 - stylistic, maybe should switch to
	@# SC2154 - unnecessary due to split
	@# SC2034 - unnecessary due to split
	shellcheck -s bash -f gcc --exclude SC2001,SC2120,SC2119,SC2129,SC2044,SC2154,SC2034 parts/[023456789]*

.PHONY: help test shellcheck shellcheck-parts docs

RESULTS := $(wildcard .asv/results/*) $(wildcard .asv/results/*/*)

# Update benchmarking script
benchmarks/benchmarks.py: benchmarks.sh gxadmin
	benchmarks.sh > benchmarks/benchmarks.py

# Run the benchmarks
benchmark: benchmarks/benchmarks.py ## Run the asv benchmarks
	asv run
	git add .asv

# Collect results
benchmark-publish: $(RESULTS) ## Publish benchmark results to docs/benchmarking/
	asv publish -o docs/benchmarking/
