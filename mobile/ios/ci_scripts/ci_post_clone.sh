#!/bin/sh

# Fail this script if any subcommand fails.
set -e

# The default execution directory of this script is the ci_scripts directory.
# Go to the root of the repo (one level up from ios, two levels up from ci_scripts?)
# Actually, $CI_PRIMARY_REPOSITORY_PATH points to the root of the cloned repo.
# In FLutter projects, the root usually contains pubspec.yaml.
# Let's assume standard structure.

echo "Navigate to project root..."
cd $CI_PRIMARY_REPOSITORY_PATH

echo "Installing Flutter..."
# Use Homebrew to install Flutter
HOMEBREW_NO_AUTO_UPDATE=1 brew install --cask flutter

echo "Installing CocoaPods..."
# Use Homebrew to install CocoaPods (if not present, though usually is)
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods

echo "Flutter version:"
flutter --version

echo "Installing Flutter dependencies..."
flutter pub get

echo "Installing CocoaPods dependencies..."
cd ios
pod install
echo "Pod install complete."
