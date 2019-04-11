PARTS=$(sort $(wildcard parts/*.sh))

README.md: gxadmin
	sed -n -i '/^## Commands$$/q;p' README.md
	./gxadmin meta cmdlist >> README.md

gxadmin: $(PARTS)
	cat $(PARTS) > gxadmin

test:
	./test.sh

.PHONY = update_readme
