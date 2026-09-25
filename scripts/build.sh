#!/bin/bash

# Script to build the Flutter app for different environments
# Usage: ./scripts/build.sh [env: dev(default), staging, prod] [platform: all(default), apk, appbundle, web]

ENV="${1:-dev}"
PLATFORM="${2:-all}"

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}🏗️  Building for $ENV environment...${NC}"

# Set build number/version
BUILD_NUMBER=$(date +%Y%m%d%H%M)
VERSION="1.0.0"  # Update this as needed

# Common build arguments
BUILD_ARGS="--release --no-tree-shake-icons --suppress-analytics"

# Environment specific arguments
case $ENV in
  dev)
    BUILD_ARGS+=" --dart-define=ENV=dev"
    ;;
  staging)
    BUILD_ARGS+=" --dart-define=ENV=staging"
    ;;
  prod)
    BUILD_ARGS+=" --dart-define=ENV=prod"
    ;;
  *)
    echo "❌ Unknown environment: $ENV"
    echo "Usage: ./scripts/build.sh [dev|staging|prod] [all|apk|appbundle|web]"
    exit 1
    ;;
esac

# Create output directory
OUTPUT_DIR="build/outputs/${ENV}"
mkdir -p "$OUTPUT_DIR"

# Build based on platform
case $PLATFORM in
  all)
    echo "📱 Building APK..."
    flutter build apk $BUILD_ARGS --split-per-abi
    
    echo "📦 Building App Bundle..."
    flutter build appbundle $BUILD_ARGS
    
    echo "🌐 Building Web..."
    flutter build web $BUILD_ARGS --web-renderer html --csp
    
    # Copy outputs
    cp build/app/outputs/flutter-apk/app-*-release.apk "$OUTPUT_DIR/" 2>/dev/null || true
    cp build/app/outputs/bundle/release/app-release.aab "$OUTPUT_DIR/" 2>/dev/null || true
    cp -r build/web "$OUTPUT_DIR/" 2>/dev/null || true
    ;;
    
  apk)
    echo "📱 Building APK..."
    flutter build apk $BUILD_ARGS --split-per-abi
    cp build/app/outputs/flutter-apk/app-*-release.apk "$OUTPUT_DIR/" 2>/dev/null || true
    ;;
    
  appbundle)
    echo "📦 Building App Bundle..."
    flutter build appbundle $BUILD_ARGS
    cp build/app/outputs/bundle/release/app-release.aab "$OUTPUT_DIR/" 2>/dev/null || true
    ;;
    
  web)
    echo "🌐 Building Web..."
    flutter build web $BUILD_ARGS --web-renderer html --csp
    cp -r build/web "$OUTPUT_DIR/" 2>/dev/null || true
    ;;
    
  *)
    echo "❌ Unknown platform: $PLATFORM"
    echo "Usage: ./scripts/build.sh [dev|staging|prod] [all|apk|appbundle|web]"
    exit 1
    ;;
esac

echo -e "\n${GREEN}✅ Build completed! Outputs are in: $OUTPUT_DIR${NC}"
find "$OUTPUT_DIR" -type f -exec ls -lh {} \;
