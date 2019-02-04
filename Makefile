update_readme:
	sed -n -i '/^## Commands$$/q;p' README.md
	./gxadmin cmdlist >> README.md

.PHONY = update_readme
