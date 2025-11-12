# Docker Stats .deb Builder
# Multi-architecture Dockerfile using Cirrus Labs Flutter images

FROM ghcr.io/cirruslabs/flutter:3.35.7

# Install additional system dependencies for .deb building
RUN apt-get update && apt-get install -y \
    dpkg-dev \
    debhelper \
    && rm -rf /var/lib/apt/lists/*

# Enable Flutter linux desktop support
RUN flutter config --enable-linux-desktop

# Set the working directory
WORKDIR /app

# Copy pubspec files first for better caching
COPY pubspec.yaml pubspec.lock ./

# Install project dependencies (cached if pubspec doesn't change)
RUN flutter pub get

# Copy the rest of the project files
COPY . .

# Default command - keep container running for development
CMD ["bash"]