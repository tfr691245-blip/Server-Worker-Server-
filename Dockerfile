# Use your existing base image
FROM ubuntu:noble 

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install the critical SASL and SSL components
RUN apt-get update && apt-get install -y \
    libsasl2-modules \
    ca-certificates \
    postfix \
    sasl2-bin \
    && rm -rf /var/lib/apt/lists/*

# Your existing app setup code follows...
