.PHONY: install

install:
	@echo "Installing yolo -> /usr/local/bin/yolo"
	@ln -sf $(CURDIR)/manage.sh /usr/local/bin/yolo 2>/dev/null || \
		(echo "Permission denied, retrying with sudo..." && sudo ln -sf $(CURDIR)/manage.sh /usr/local/bin/yolo)
	@echo "Done"
