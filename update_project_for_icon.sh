#!/bin/bash

# Make a backup of the project file
cp "Soul AI.xcodeproj/project.pbxproj" "Soul AI.xcodeproj/project.pbxproj.bak2"

# Add the app icon reference
sed -i '' 's/ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;/ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;\n\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;/g' "Soul AI.xcodeproj/project.pbxproj"

echo "Project file updated to use the app icon. A backup was created at Soul AI.xcodeproj/project.pbxproj.bak2" 