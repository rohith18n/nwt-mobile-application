#!/bin/bash

# Script to run the Flutter app in development mode
# Usage: ./scripts/dev.sh [platform: web(default), android, ios]

PLATFORM="${1:-web}"
PORT=55555

case $PLATFORM in
  web)
    echo "🚀 Starting Flutter Web on port $PORT..."
    flutter run -d chrome --web-port=$PORT --web-renderer html --web-browser-flag "--disable-web-security"
    ;;
  android)
    echo "🚀 Starting Flutter Android..."
    flutter run -d emulator-5554  # Replace with your device ID
    ;;
  ios)
    echo "🚀 Starting Flutter iOS..."
    flutter run -d "iPhone 15"  # Replace with your simulator name
    ;;
  *)
    echo "❌ Unknown platform: $PLATFORM"
    echo "Usage: ./scripts/dev.sh [web|android|ios]"
    exit 1
    ;;
esac
