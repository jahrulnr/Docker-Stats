# Docker Stats .deb Builder
# Multi-architecture Dockerfile using Cirrus Labs Flutter images

ARG BASE=ghcr.io/cirruslabs/flutter:3.35.7
FROM ${BASE}

# Set the working directory
WORKDIR /app

# Install additional system dependencies for .deb building
RUN apt-get update && apt-get install -y \
    dpkg-dev \
    debhelper \
		cmake clang ninja-build pkg-config libgtk-3-dev mesa-utils \
    && rm -rf /var/lib/apt/lists/* \
		# Enable Flutter linux desktop support
		&& flutter config --enable-linux-desktop

# Copy pubspec files first for better caching
COPY pubspec.yaml pubspec.lock ./

# Install project dependencies (cached if pubspec doesn't change)
RUN flutter pub get

# Copy the rest of the project files
COPY . .

# Default command - keep container running for development
CMD ["bash"]