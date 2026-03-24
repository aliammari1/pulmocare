#!/usr/bin/env bash
set -e

echo "Starting monorepo setup script..."

# Setup API
echo "Setting up backend..."
cd apps/api
# Add API setup logic here
cd ../..

# Setup Mobile
echo "Setting up mobile app..."
cd apps/mobile
if command -v flutter &> /dev/null; then
    flutter pub get
else
    echo "Flutter is not installed. Skipping..."
fi
cd ../..

echo "Setup complete!"
