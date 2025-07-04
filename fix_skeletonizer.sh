#!/bin/bash

echo "Fixing skeletonizer version in pubspec.yaml"

# Check if pubspec.yaml exists
if [ -f "pubspec.yaml" ]; then
  echo "Found pubspec.yaml"
  
  # Create a backup of the original pubspec.yaml
  cp pubspec.yaml pubspec.yaml.bak
  
  # Add skeletonizer to dependency_overrides
  if grep -q "dependency_overrides:" pubspec.yaml; then
    if grep -q "skeletonizer:" pubspec.yaml; then
      if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' 's/skeletonizer: .*/skeletonizer: 0.4.0/g' pubspec.yaml
      else
        # Linux
        sed -i 's/skeletonizer: .*/skeletonizer: 0.4.0/g' pubspec.yaml
      fi
    else
      if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' '/dependency_overrides:/a\\  skeletonizer: 0.4.0' pubspec.yaml
      else
        # Linux
        sed -i '/dependency_overrides:/a\\  skeletonizer: 0.4.0' pubspec.yaml
      fi
    fi
  else
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS
      sed -i '' '$ a\\dependency_overrides:\\  skeletonizer: 0.4.0' pubspec.yaml
    else
      # Linux
      sed -i '$ a\\dependency_overrides:\\  skeletonizer: 0.4.0' pubspec.yaml
    fi
  fi
  
  echo "Added skeletonizer 0.4.0 to dependency_overrides"
  
  # Run flutter pub get to update dependencies
  flutter pub get
  
  echo "Dependencies updated successfully"
else
  echo "pubspec.yaml not found"
  exit 1
fi 