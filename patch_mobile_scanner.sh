#!/bin/bash

# Find the mobile_scanner plugin directory
PLUGIN_DIR=".flutter-plugins-dependencies"
MOBILE_SCANNER_PATH=""

if [ -f "$PLUGIN_DIR" ]; then
  echo "Found .flutter-plugins-dependencies"
  
  # Extract the mobile_scanner path from the dependencies file
  MOBILE_SCANNER_PATH=$(grep -o '"mobile_scanner":"[^"]*"' "$PLUGIN_DIR" | cut -d'"' -f4)
  
  if [ -n "$MOBILE_SCANNER_PATH" ]; then
    echo "Found mobile_scanner plugin at $MOBILE_SCANNER_PATH"
    
    # Check if iOS directory exists
    if [ -d "$MOBILE_SCANNER_PATH/ios" ]; then
      echo "Found iOS directory"
      
      # Check if podspec file exists
      if [ -f "$MOBILE_SCANNER_PATH/ios/mobile_scanner.podspec" ]; then
        echo "Found mobile_scanner.podspec"
        
        # Create a backup of the original podspec
        cp "$MOBILE_SCANNER_PATH/ios/mobile_scanner.podspec" "$MOBILE_SCANNER_PATH/ios/mobile_scanner.podspec.bak"
        
        # Replace the entire podspec file with a simplified version that forces iOS 13.0
        cat > "$MOBILE_SCANNER_PATH/ios/mobile_scanner.podspec" << 'EOL'
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint mobile_scanner.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'mobile_scanner'
  s.version          = '3.0.0'
  s.summary          = 'An universal scanner for Flutter.'
  s.description      = <<-DESC
A Flutter plugin for iOS and Android that allows for ML Kit barcode scanning.
                       DESC
  s.homepage         = 'https://github.com/juliansteenbakker/mobile_scanner'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Julian Steenbakker' => 'juliansteenbakker97@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
EOL
        
        echo "Created simplified mobile_scanner.podspec with iOS 13.0 target"
      else
        echo "mobile_scanner.podspec not found"
      fi
    else
      echo "iOS directory not found"
    fi
  else
    echo "Could not find mobile_scanner path in dependencies"
  fi
else
  echo ".flutter-plugins-dependencies not found"
fi 