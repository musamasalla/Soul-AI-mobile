#!/bin/bash

# Make a backup of the project file
cp "Soul AI.xcodeproj/project.pbxproj" "Soul AI.xcodeproj/project.pbxproj.bak"

# Remove the app icon reference
sed -i '' 's/ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;//g' "Soul AI.xcodeproj/project.pbxproj"

echo "Project file updated. A backup was created at Soul AI.xcodeproj/project.pbxproj.bak" 