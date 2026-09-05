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

dots: dotfiles mimeconf mpv pkgit bash rdfmconf gimp darktable gh git lazygit rofi okular alacritty tmux vim lyconf nvim
base: pacup base-install ly devel fetch dtop det wtf rdfm dacam helium-browser steam appache

xorginit:
	$(PACMAN) -S $(XORG)
wayinit:
	$(PACMAN) -S $(WAY)

x: all xorginit shot px sxat rsxiv sxwm few xorgconf
way: all wayinit whot pw swat

gpu:
	$(PACMAN) -S xf86-video-intel

xorgconf:
	echo export MOZ_USE_XINPUT2=1 | sudo tee /etc/profile.d/use-xinput2.sh
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

WAYDROID_MODULES := binder_linux ashmem_linux

waydroid:
	@$(PACMAN) -S $(NEED) xorg-xwayland cage waydroid
	@cp -f applications/waydroid.desktop $(HOMEDIR)/.local/share/applications/
	@echo "== Checking binder/ashmem modules =="
	@if ! lsmod | grep -q binder_linux; then \
		sudo modprobe binder_linux devices="binder,hwbinder,vndbinder" 2>/dev/null || \
		echo "!! binder_linux module missing — install binder_linux-dkms (AUR) or check for /dev/binderfs"; \
	fi
	@if ls /dev/binderfs >/dev/null 2>&1 || mount | grep -q binder; then \
		echo "binderfs OK"; \
	fi
	@if ! lsmod | grep -q ashmem_linux; then \
		sudo modprobe ashmem_linux 2>/dev/null || echo "!! ashmem_linux not available (may be unneeded on newer kernels)"; \
	fi
	@echo "== Initializing waydroid (skips if already done) =="
	@sudo test -f /var/lib/waydroid/waydroid_base.prop || sudo waydroid init
	@echo "== Starting container =="
	@sudo systemctl enable --now waydroid-container.service
	@echo "== Waiting for container to come up =="
	@for i in $$(seq 1 15); do \
		sudo waydroid status 2>/dev/null | grep -q "Container:.*RUNNING" && break; \
		sleep 1; \
	done
	@sudo waydroid status | grep -q "Container:.*RUNNING" || \
		(echo "!! Container failed to start — check: sudo journalctl -u waydroid-container -e" && exit 1)
	@echo "== Starting session in background =="
	@waydroid session start > /tmp/waydroid-session.log 2>&1 & disown
	@sleep 3
	@echo "== Enabling fake WiFi so apps see a connection =="
	@waydroid shell settings put global wifi_on 1 2>/dev/null || true
	@waydroid prop set persist.waydroid.fake_wifi true 2>/dev/null || true
	@echo "== Done. Verify with: sudo waydroid status; ip addr show waydroid0 =="

waydroid-launch:
	@cage waydroid session start &

zotero-clean:
	rm -rf $(HOMEDIR)/.mozilla

.PHONY: dotfiles mimeconf base dots base base-install x way mime mpv pkgit bash rdfmconf gimp darktable \
	dunst gh git i3 lazygit rofi okular alacritty tmux vim lyconf nvim shot px sxat rsxiv i3 clean pkgclean \
	docker-install docker-configure docker-group docker-setup zotero zotero-install zotero-arc baph onlyoffice \
	signal-desktop-beta protonup-qt helium-browser thinkfan powertop

