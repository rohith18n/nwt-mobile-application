#!/bin/bash

# Script to run the Flutter web app on port 55555
# Usage: ./scripts/run_web.sh [port: 55555]

PORT="${1:-55555}"

echo "🌐 Starting Flutter Web on port $PORT..."
flutter run -d chrome --web-port=$PORT --web-renderer html --web-browser-flag "--disable-web-security"
