#!/bin/bash

echo "Fixing skeletonizer version in pubspec.yaml"

# Check if pubspec.yaml exists
if [ -f "pubspec.yaml" ]; then
  echo "Found pubspec.yaml"
  
  # Create a backup of the original pubspec.yaml
  cp pubspec.yaml pubspec.yaml.bak
  
  # Replace skeletonizer version with a compatible one
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' 's/skeletonizer: .*/skeletonizer: ^0.7.0/g' pubspec.yaml
  else
    # Linux
    sed -i 's/skeletonizer: .*/skeletonizer: ^0.7.0/g' pubspec.yaml
  fi
  
  echo "Updated skeletonizer version to ^0.7.0"
  
  # Run flutter pub get to update dependencies
  flutter pub get
  
  echo "Dependencies updated successfully"
else
  echo "pubspec.yaml not found"
  exit 1
fi 