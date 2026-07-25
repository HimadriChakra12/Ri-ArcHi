include make/help.mk


HOMEDIR ?= $(shell getent passwd $$(logname 2>/dev/null || echo $(SUDO_USER)) | cut -d: -f6)
HOMEDIR ?= $(shell getent passwd $$(logname) | cut -d: -f6)
RIYA := $(shell pwd)

include make/command.mk
include make/dots.mk
include make/mime.mk
include make/pkg.mk
include make/pacman.mk
include make/input.mk
include make/docker.mk
include make/wifi.mk
include make/wine.mk



all: welcome-banner2 time base dots

time:
	sudo timedatectl set-timezone Asia/Dhaka

tty:
	sudo usermod -aG tty himadri

pac: pacinit pacupdate reflector

pacup:
	$(PACMAN) -Syu

docker: docker-install docker-configure docker-group docker-setup

base-install:
	$(PACMAN) -S $(NEED) $(CORE) $(RI) $(XDG) $(GTK) $(UTILS) $(FONT) $(MEDIA) $(GVFS) $(ROFI) $(LANG) $(SHELLUTIL) 

devel:
	$(PACMAN) -S $(CLANG) $(NEED)

dots: dotfiles mimeconf mpv pkgit bash rdfmconf gimp darktable dunst gh git lazygit rofi okular alacritty tmux vim lyconf nvim
base: pacup base-install ly devel fetch dtop det wtf rdfm dacam chromium

xorginit:
	$(PACMAN) -S $(XORG)
wayinit:
	$(PACMAN) -S $(WAY)

x: xorginit shot px sxat rsxiv i3 few
way: wayinit whot pw swat

gpu:
	$(PACMAN) -S xf86-video-intel

xorgconf:
	sudo cp $(RIYA)/xorg.config.d/* -f /etc/X11/xorg.conf.d/
	ls /etc/X11/xorg.conf.d/

clean:
	@echo "==> Cleaning package cache..."
	@sudo paccache -r || true
	@$(PACMAN) -Scc --noconfirm || true
	@echo "==> Removing orphan packages..."
	@if orphans=$$($(PACMAN) -Qdtq 2>/dev/null); then \
		if [ -n "$$orphans" ]; then \
		$(PACMAN) -Rns $(NOC) $$orphans; \
		fi; \
		else \
		echo "No orphaned packages found."; \
		fi
	@echo "==> Vacuuming journal..."
	@sudo journalctl --vacuum-size=500M || true
	@echo "==> Truncating log files..."
	@sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; || true
	@echo "==> Cleaning temporary directories..."
	@sudo rm -rf /tmp/* /var/tmp/*
	@echo "==> Cleaning Docker..."
	@if command -v docker >/dev/null 2>&1; then \
		sudo docker system prune -a --volumes -f; \
	else \
		echo "Docker not installed."; \
	fi
	@echo "==> Large files in /root..."
	@sudo find /root -type f -size +50M -exec du -h {} \; 2>/dev/null || true
	@echo "==> Large directories in /opt..."
	@sudo du -hxd1 /opt 2>/dev/null | sort -h | awk '$$1 ~ /[0-9]M|G/ {print}'
	@echo "==> Cleanup complete."

waydroid:
	$(PACMAN) -S $(NEED) xorg-xwayland cage waydroid
	sudo waydroid init
	sudo waydroid container start

zotero-clean:
	rm -rf $(HOMEDIR)/.mozilla

.PHONY: dotfiles mimeconf base dots base base-install x way mime mpv pkgit bash rdfmconf gimp darktable \
	dunst gh git i3 lazygit rofi okular alacritty tmux vim lyconf nvim shot px sxat rsxiv i3 clean pkgclean \
	docker-install docker-configure docker-group docker-setup zotero zotero-install zotero-arc chromium baph onlyoffice

