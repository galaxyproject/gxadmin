PARTS=$(sort $(wildcard parts/*.sh))

gxadmin: $(PARTS)
	cat $(PARTS) > gxadmin


update_readme: gxadmin
	sed -n -i '/^## Commands$$/q;p' README.md
	./gxadmin meta cmdlist >> README.md

.PHONY = update_readme
