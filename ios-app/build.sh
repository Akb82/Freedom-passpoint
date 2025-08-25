#!/bin/bash

# Freedom WiFi iOS App Build Script
# Builds the iOS app for distribution

echo "🚀 Building Freedom WiFi iOS App..."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install Xcode from App Store."
    exit 1
fi

# Navigate to project directory
cd "$(dirname "$0")"

PROJECT_NAME="FreedomWiFi"
SCHEME_NAME="FreedomWiFi"
BUILD_DIR="build"

echo "📁 Project: $PROJECT_NAME"
echo "🎯 Scheme: $SCHEME_NAME"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

# Build for simulator (for testing)
echo "📱 Building for iOS Simulator..."
xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
           -scheme "$SCHEME_NAME" \
           -destination 'platform=iOS Simulator,name=iPhone 15' \
           -configuration Debug \
           -derivedDataPath "$BUILD_DIR/DerivedData" \
           build

if [ $? -eq 0 ]; then
    echo "✅ Simulator build successful"
else
    echo "❌ Simulator build failed"
    exit 1
fi

# Archive for device (requires valid provisioning profile)
echo "📦 Creating archive for device..."
xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
           -scheme "$SCHEME_NAME" \
           -destination 'generic/platform=iOS' \
           -configuration Release \
           -derivedDataPath "$BUILD_DIR/DerivedData" \
           -archivePath "$BUILD_DIR/${PROJECT_NAME}.xcarchive" \
           archive

if [ $? -eq 0 ]; then
    echo "✅ Archive created successfully"
    echo "📍 Archive location: $BUILD_DIR/${PROJECT_NAME}.xcarchive"
    
    # Export IPA (requires proper provisioning)
    echo "📤 Exporting IPA..."
    
    # Create export options plist
    cat > "$BUILD_DIR/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>compileBitcode</key>
    <false/>
    <key>stripSwiftSymbols</key>
    <true/>
</dict>
</plist>
EOF
    
    xcodebuild -exportArchive \
               -archivePath "$BUILD_DIR/${PROJECT_NAME}.xcarchive" \
               -exportPath "$BUILD_DIR/IPA" \
               -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist"
    
    if [ $? -eq 0 ]; then
        echo "✅ IPA exported successfully"
        echo "📍 IPA location: $BUILD_DIR/IPA/${PROJECT_NAME}.ipa"
    else
        echo "⚠️ IPA export failed (check provisioning profile and team ID)"
    fi
    
else
    echo "❌ Archive creation failed"
    exit 1
fi

echo ""
echo "🎉 Build process completed!"
echo ""
echo "📋 Next steps:"
echo "   1. Update YOUR_TEAM_ID in build script with your Apple Developer Team ID"
echo "   2. Configure proper provisioning profile in Xcode"
echo "   3. Update server URL in ViewController.swift"
echo "   4. Test on physical iOS device"
echo "   5. Distribute via TestFlight or Ad-hoc"
echo ""
echo "📖 For distribution help, check ios-app/README.md"