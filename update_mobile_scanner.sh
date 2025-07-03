#!/bin/bash

# Get the path to the mobile_scanner plugin
MOBILE_SCANNER_PATH=".symlinks/plugins/mobile_scanner/ios"

if [ -d "ios/$MOBILE_SCANNER_PATH" ]; then
  echo "Found mobile_scanner plugin at ios/$MOBILE_SCANNER_PATH"
  
  # Check if Podspec file exists
  if [ -f "ios/$MOBILE_SCANNER_PATH/mobile_scanner.podspec" ]; then
    echo "Found mobile_scanner.podspec"
    
    # Update the deployment target in the podspec file
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS
      sed -i '' 's/s.platform = :ios, .*/s.platform = :ios, '\''14.0'\''/g' "ios/$MOBILE_SCANNER_PATH/mobile_scanner.podspec"
    else
      # Linux
      sed -i 's/s.platform = :ios, .*/s.platform = :ios, '\''14.0'\''/g' "ios/$MOBILE_SCANNER_PATH/mobile_scanner.podspec"
    fi
    
    echo "Updated mobile_scanner.podspec deployment target to 14.0"
  else
    echo "mobile_scanner.podspec not found"
  fi
else
  echo "mobile_scanner plugin directory not found"
fi 