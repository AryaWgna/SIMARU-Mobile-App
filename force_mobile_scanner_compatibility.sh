#!/bin/bash

# Get the path to the mobile_scanner plugin
MOBILE_SCANNER_PATH=".symlinks/plugins/mobile_scanner/ios"

if [ -d "ios/$MOBILE_SCANNER_PATH" ]; then
  echo "Found mobile_scanner plugin at ios/$MOBILE_SCANNER_PATH"
  
  # Check if Podspec file exists
  if [ -f "ios/$MOBILE_SCANNER_PATH/mobile_scanner.podspec" ]; then
    echo "Found mobile_scanner.podspec"
    
    # Create a backup of the original podspec
    cp "ios/$MOBILE_SCANNER_PATH/mobile_scanner.podspec" "ios/$MOBILE_SCANNER_PATH/mobile_scanner.podspec.bak"
    
    # Replace the entire podspec file with a simplified version that forces iOS 16.0
    cat > "ios/$MOBILE_SCANNER_PATH/mobile_scanner.podspec" << 'EOL'
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
  s.platform = :ios, '16.0'
  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
EOL
    
    echo "Created simplified mobile_scanner.podspec with iOS 16.0 target"
  else
    echo "mobile_scanner.podspec not found"
  fi
else
  echo "mobile_scanner plugin directory not found"
fi 