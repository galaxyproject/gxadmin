PARTS=$(sort $(wildcard parts/*.sh))
TMP := $(shell mktemp)

all: gxadmin test README.md

README.md:
	@cat $(PARTS) > .tmpgxadmin
	@chmod +x .tmpgxadmin
	sed -n -i '/^## Commands$$/q;p' README.md
	./.tmpgxadmin meta cmdlist >> README.md
	@rm -f .tmpgxadmin

gxadmin: $(PARTS)
	cat $(PARTS) > gxadmin
	chmod +x gxadmin

test:
	@cat $(PARTS) > .tmpgxadmin
	@chmod +x .tmpgxadmin
	./test.sh
	@rm -f .tmpgxadmin

shellcheck: gxadmin
	@# SC2001 - stylistic, no thank you!
	@# SC2119 - literally no clue
	@# SC2120 - literally no clue
	@# SC2129 - stylistic, maybe should switch to
	shellcheck -s bash -f gcc --exclude SC2001,SC2120,SC2119,SC2129,SC2044 gxadmin
	shellcheck -s bash -f gcc --exclude SC2001,SC2120,SC2119,SC2129,SC2044 gxadmin-complete.sh

shellcheck-parts:
	@# SC2001 - stylistic, no thank you!
	@# SC2119 - literally no clue
	@# SC2120 - literally no clue
	@# SC2129 - stylistic, maybe should switch to
	@# SC2154 - unnecessary due to split
	@# SC2034 - unnecessary due to split
	shellcheck -s bash -f gcc --exclude SC2001,SC2120,SC2119,SC2129,SC2044,SC2154,SC2034 parts/[023456789]*

.PHONY: test shellcheck shellcheck-parts README.md
