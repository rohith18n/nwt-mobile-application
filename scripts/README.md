# Flutter Project Scripts

This directory contains useful scripts for Flutter development.

## Setup

1. Make all scripts executable (if not already):
   ```bash
   chmod +x scripts/*.sh
   ```

2. To use the utility functions in your shell, add this to your `~/.zshrc` or `~/.bashrc`:
   ```bash
   # Add Flutter utils to your shell
   export PATH="$PATH:/Users/nwtdev/nwt-app/scripts"
   source /Users/nwtdev/nwt-app/scripts/utils.sh
   ```

3. Reload your shell:
   ```bash
   source ~/.zshrc  # or source ~/.bashrc
   ```

## Available Scripts

### Development
- `dev.sh` - Run the app in development mode
  ```bash
  ./scripts/dev.sh         # Run web (default)
  ./scripts/dev.sh web     # Run web
  ./scripts/dev.sh android # Run Android
  ./scripts/dev.sh ios     # Run iOS
  ```

### Building
- `build.sh` - Build the app for different environments
  ```bash
  ./scripts/build.sh           # Build all platforms for dev
  ./scripts/build.sh prod      # Build all platforms for production
  ./scripts/build.sh dev web   # Build only web for dev
  ./scripts/build.sh prod apk  # Build only APK for production
  ```

### Web-Specific
- `run_web.sh` - Run web app on port 55555
  ```bash
  ./scripts/run_web.sh      # Run on port 55555
  ./scripts/run_web.sh 8080 # Run on custom port
  ```

### Utilities
After sourcing `utils.sh` in your shell, these commands become available:

- `flutter_clean`   - Clean and get dependencies
- `run_tests`      - Run all tests
- `generate_code`  - Run build_runner
- `analyze_code`   - Analyze code
- `format_code`    - Format code
- `show_help`      - Show available commands

## Adding to PATH (Optional)

For easier access, you can add the scripts directory to your PATH:

1. Add this to your `~/.zshrc` or `~/.bashrc`:
   ```bash
   export PATH="$PATH:/Users/nwtdev/nwt-app/scripts"
   ```

2. Then you can run scripts directly:
   ```bash
   dev.sh
   build.sh
   run_web.sh
   ```
