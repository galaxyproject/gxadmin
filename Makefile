PARTS=$(sort $(wildcard parts/*.sh))

all: README.md test

README.md: gxadmin
	sed -n -i '/^## Commands$$/q;p' README.md
	./gxadmin meta cmdlist >> README.md

gxadmin: $(PARTS)
	cat $(PARTS) > gxadmin
	chmod +x gxadmin

test:
	./test.sh

.PHONY = update_readme
