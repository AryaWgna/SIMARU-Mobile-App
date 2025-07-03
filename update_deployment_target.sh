#!/bin/bash

# Update deployment target in project.pbxproj
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 12.0;/IPHONEOS_DEPLOYMENT_TARGET = 15.0;/g' ios/Runner.xcodeproj/project.pbxproj
else
  # Linux
  sed -i 's/IPHONEOS_DEPLOYMENT_TARGET = 12.0;/IPHONEOS_DEPLOYMENT_TARGET = 15.0;/g' ios/Runner.xcodeproj/project.pbxproj
fi

echo "Updated iOS deployment target to 15.0" 