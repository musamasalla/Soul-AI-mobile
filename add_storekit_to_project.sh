#!/bin/bash

# This script adds the StoreKit configuration file to the Xcode project

# Get the project file path
PROJECT_FILE="Soul AI.xcodeproj/project.pbxproj"

# Check if the file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo "Project file not found: $PROJECT_FILE"
    exit 1
fi

# Check if the StoreKit configuration file exists
STOREKIT_FILE="Soul AI/Configuration/Subscriptions.storekit"
if [ ! -f "$STOREKIT_FILE" ]; then
    echo "StoreKit configuration file not found: $STOREKIT_FILE"
    exit 1
fi

# Generate a unique file reference ID
FILE_REF_ID=$(uuidgen | tr -d '-' | tr '[:upper:]' '[:lower:]' | head -c 24)

# Add the file reference to the project file
sed -i '' -e '//* Begin PBXFileReference section/a\
		'"$FILE_REF_ID"' /* Subscriptions.storekit */ = {isa = PBXFileReference; lastKnownFileType = text; path = Subscriptions.storekit; sourceTree = "<group>"; };
' "$PROJECT_FILE"

# Generate a unique build file ID
BUILD_FILE_ID=$(uuidgen | tr -d '-' | tr '[:upper:]' '[:lower:]' | head -c 24)

# Add the build file to the project file
sed -i '' -e '//* Begin PBXBuildFile section/a\
		'"$BUILD_FILE_ID"' /* Subscriptions.storekit in Resources */ = {isa = PBXBuildFile; fileRef = '"$FILE_REF_ID"' /* Subscriptions.storekit */; };
' "$PROJECT_FILE"

# Find the main group ID
MAIN_GROUP_ID=$(grep -A 1 "mainGroup = " "$PROJECT_FILE" | tail -n 1 | sed 's/^[[:space:]]*\([^[:space:]]*\)[[:space:]].*/\1/')

# Add the file to the main group
sed -i '' -e '/'"$MAIN_GROUP_ID"' = {/,/children = (/s/children = (/children = (\
				'"$FILE_REF_ID"' \/* Subscriptions.storekit *\/,/' "$PROJECT_FILE"

# Find the resources build phase ID
RESOURCES_PHASE_ID=$(grep -A 1 "Resources */ = {" "$PROJECT_FILE" | head -n 1 | sed 's/^[[:space:]]*\([^[:space:]]*\)[[:space:]].*/\1/')

# Add the file to the resources build phase
sed -i '' -e '/'"$RESOURCES_PHASE_ID"' = {/,/files = (/s/files = (/files = (\
				'"$BUILD_FILE_ID"' \/* Subscriptions.storekit in Resources *\/,/' "$PROJECT_FILE"

echo "StoreKit configuration file added to the Xcode project" 