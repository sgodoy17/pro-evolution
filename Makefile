.PHONY: status
status:
	bash ./resources/kind.sh status

.PHONY: unistall
uninstall:
	bash ./resources/kind.sh delete

.PHONY: install
install: uninstall
	bash ./resources/kind.sh create
