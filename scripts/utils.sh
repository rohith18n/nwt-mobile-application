#!/bin/bash

# Utility script for common Flutter tasks
# Source this file in your shell: source scripts/utils.sh

# Run Flutter clean and get dependencies
function flutter_clean {
  echo "🧹 Cleaning Flutter project..."
  flutter clean
  flutter pub get
  echo "✅ Done!"
}

# Run all tests
function run_tests {
  echo "🧪 Running tests..."
  flutter test
  echo "✅ Tests completed!"
}

# Generate code (build_runner, etc.)
function generate_code {
  echo "🔧 Generating code..."
  flutter pub run build_runner build --delete-conflicting-outputs
  echo "✅ Code generation completed!"
}

# Analyze code
function analyze_code {
  echo "🔍 Analyzing code..."
  flutter analyze
  echo "✅ Analysis completed!"
}

# Format code
function format_code {
  echo "✨ Formatting code..."
  flutter format .
  echo "✅ Formatting completed!"
}

# Show help
function show_help {
  echo "Flutter Project Scripts"
  echo "----------------------"
  echo "Available commands:"
  echo "  flutter_clean    - Clean and get dependencies"
  echo "  run_tests       - Run all tests"
  echo "  generate_code   - Run build_runner"
  echo "  analyze_code    - Analyze code"
  echo "  format_code     - Format code"
  echo "  show_help       - Show this help"
}

echo "Flutter utils loaded! Type 'show_help' to see available commands."
