# Docker Stats .deb Package Builder Makefile
# Provides targets for building .deb packages using Docker

.PHONY: help build build-amd64 build-arm64 build-all clean dev test install

# Default target
help:
	@echo "🐳 Docker Stats .deb Builder"
	@echo "============================"
	@echo ""
	@echo "Available targets:"
	@echo "  build-amd64    Build .deb package for AMD64 architecture"
	@echo "  build-arm64    Build .deb package for ARM64 architecture"
	@echo "  build-all      Build .deb packages for both architectures"
	@echo "  build          Alias for build-all"
	@echo "  clean          Clean build artifacts"
	@echo "  dev            Start development container"
	@echo "  test           Test the built packages"
	@echo "  install        Install the built packages locally"
	@echo ""
	@echo "Usage:"
	@echo "  make build-amd64    # Build for AMD64 only"
	@echo "  make build-all      # Build for both architectures"
	@echo "  make dev            # Start development environment"

# Get version from pubspec.yaml
VERSION := $(shell grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//')

# Docker image name
IMAGE_NAME := docker-stats-builder
BASE_IMAGE_AMD64 := ghcr.io/cirruslabs/flutter:3.35.7
BASE_IMAGE_ARM64 := ghcr.io/cirruslabs/flutter:3.35.7@sha256:83ce9c8cc7a96d0f7bdf53a3d17ddcc3ee8933546cac8c373f422ed113e57f8f

# Build targets
build: build-all

build-all: build-amd64 build-arm64
	@echo "✅ All builds completed!"
	@ls -la dist/*.deb 2>/dev/null || echo "No .deb files found"

build-amd64:
	@echo "🔨 Building for AMD64..."
	@mkdir -p dist
	docker buildx build \
		--platform linux/amd64 \
		--build-arg "BASE=$(BASE_IMAGE_AMD64)" \
		--tag $(IMAGE_NAME)-amd64 \
		--load \
		.
	@docker run -d --name $(IMAGE_NAME)-temp-amd64 $(IMAGE_NAME)-amd64 sleep 300
	@docker exec $(IMAGE_NAME)-temp-amd64 /bin/bash -c '\
		echo "🏗️ Building .deb packages inside container..."; \
		VERSION=$$(grep "^version:" pubspec.yaml | sed "s/version: //" | sed "s/+.*//"); \
		echo "📋 Building version: $$VERSION"; \
		flutter clean; \
		flutter pub upgrade --major-versions; \
		flutter build linux --release; \
		pkg_dir="dist/docker-stats-app-$${VERSION}_amd64"; \
		rm -rf "$$pkg_dir"; \
		mkdir -p "$$pkg_dir/opt/docker-stats"; \
		mkdir -p "$$pkg_dir/usr/share/applications"; \
		mkdir -p "$$pkg_dir/usr/share/icons/hicolor/512x512/apps"; \
		cp -r "build/linux/x64/release/bundle/"* "$$pkg_dir/opt/docker-stats/"; \
		if [ -f "icon.jpg" ]; then cp "icon.jpg" "$$pkg_dir/usr/share/icons/hicolor/512x512/apps/docker-stats.png"; fi; \
		mkdir -p "$$pkg_dir/DEBIAN"; \
		cp -r deb_template/DEBIAN/* "$$pkg_dir/DEBIAN/"; \
		sed -i "s/{{version}}/$$VERSION/g; s/{{arch}}/amd64/g" "$$pkg_dir/DEBIAN/control"; \
		printf "[Desktop Entry]\nType=Application\nName=Docker Status\nComment=Docker container monitoring application\nExec=/opt/docker-stats/docker_stats_app\nIcon=docker-stats\nTerminal=false\nCategories=Utility;System;Monitor;\nStartupNotify=true\n" > "$$pkg_dir/usr/share/applications/docker-stats.desktop"; \
		deb_file="dist/docker-stats-app_$${VERSION}_amd64.deb"; \
		dpkg-deb --build "$$pkg_dir" "$$deb_file"; \
		echo "✅ Created: $$deb_file"'
	@docker cp $(IMAGE_NAME)-temp-amd64:/app/dist/. dist/ 2>/dev/null || true
	@docker rm -f $(IMAGE_NAME)-temp-amd64
	@docker rmi $(IMAGE_NAME)-amd64
	@echo "✅ AMD64 build completed"

build-arm64:
	@echo "🔨 Building for ARM64..."
	@mkdir -p dist
	docker buildx build \
		--platform linux/arm64 \
		--build-arg "BASE=$(BASE_IMAGE_ARM64)" \
		--tag $(IMAGE_NAME)-arm64 \
		--load \
		.
	@docker run -d --platform linux/arm64 --name $(IMAGE_NAME)-temp-arm64 $(IMAGE_NAME)-arm64 sleep 300
	@docker exec $(IMAGE_NAME)-temp-arm64 /bin/bash -c '\
		echo "🏗️ Building .deb packages inside container..."; \
		VERSION=$$(grep "^version:" pubspec.yaml | sed "s/version: //" | sed "s/+.*//"); \
		echo "📋 Building version: $$VERSION"; \
		flutter clean; \
		flutter pub upgrade --major-versions; \
		flutter build linux --release --target-platform linux-arm64; \
		pkg_dir="dist/docker-stats-app-$${VERSION}_arm64"; \
		rm -rf "$$pkg_dir"; \
		mkdir -p "$$pkg_dir/opt/docker-stats"; \
		mkdir -p "$$pkg_dir/usr/share/applications"; \
		mkdir -p "$$pkg_dir/usr/share/icons/hicolor/512x512/apps"; \
		cp -r "build/linux/arm64/release/bundle/"* "$$pkg_dir/opt/docker-stats/"; \
		if [ -f "icon.jpg" ]; then cp "icon.jpg" "$$pkg_dir/usr/share/icons/hicolor/512x512/apps/docker-stats.png"; fi; \
		mkdir -p "$$pkg_dir/DEBIAN"; \
		cp -r deb_template/DEBIAN/* "$$pkg_dir/DEBIAN/"; \
		sed -i "s/{{version}}/$$VERSION/g; s/{{arch}}/arm64/g" "$$pkg_dir/DEBIAN/control"; \
		printf "[Desktop Entry]\nType=Application\nName=Docker Status\nComment=Docker container monitoring application\nExec=/opt/docker-stats/docker_stats_app\nIcon=docker-stats\nTerminal=false\nCategories=Utility;System;Monitor;\nStartupNotify=true\n" > "$$pkg_dir/usr/share/applications/docker-stats.desktop"; \
		deb_file="dist/docker-stats-app_$${VERSION}_arm64.deb"; \
		dpkg-deb --build "$$pkg_dir" "$$deb_file"; \
		echo "✅ Created: $$deb_file"'
	@docker cp $(IMAGE_NAME)-temp-arm64:/app/dist/. dist/ 2>/dev/null || true
	@docker rm -f $(IMAGE_NAME)-temp-arm64
	@docker rmi $(IMAGE_NAME)-arm64
	@echo "✅ ARM64 build completed"

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf dist/
	@docker rmi $(IMAGE_NAME)-amd64 $(IMAGE_NAME)-arm64 2>/dev/null || true
	@docker system prune -f
	@echo "✅ Clean completed"

# Development environment
dev:
	@echo "🚀 Starting development environment..."
	docker run -it --rm \
		-v $(PWD):/app \
		-v /app/build \
		-v /app/.dart_tool \
		-w /app \
		$(IMAGE_NAME)-dev \
		bash

# Test the built packages
test: build
	@echo "🧪 Testing built packages..."
	@if [ -f "dist/docker-stats-app_$(VERSION)_amd64.deb" ]; then \
		echo "📦 Testing AMD64 package..."; \
		dpkg-deb --info dist/docker-stats-app_$(VERSION)_amd64.deb; \
		dpkg-deb --contents dist/docker-stats-app_$(VERSION)_amd64.deb | grep -E "(docker-stats|\.deb)"; \
	else \
		echo "❌ AMD64 package not found"; \
	fi
	@if [ -f "dist/docker-stats-app_$(VERSION)_arm64.deb" ]; then \
		echo "📦 Testing ARM64 package..."; \
		dpkg-deb --info dist/docker-stats-app_$(VERSION)_arm64.deb; \
		dpkg-deb --contents dist/docker-stats-app_$(VERSION)_arm64.deb | grep -E "(docker-stats|\.deb)"; \
	else \
		echo "❌ ARM64 package not found"; \
	fi

# Install packages locally (requires sudo)
install: build
	@echo "📦 Installing packages locally..."
	@sudo dpkg -i dist/docker-stats-app_$(VERSION)_*.deb
	@sudo apt-get install -f
	@echo "✅ Installation completed"
	@echo "🎯 App should now be available in your application menu"

# Show package information
info:
	@echo "📋 Package Information:"
	@echo "  Version: $(VERSION)"
	@echo "  Image: $(IMAGE_NAME)"
	@echo "  Dist dir: dist/"
	@ls -la dist/ 2>/dev/null || echo "  No packages built yet"