#!/bin/bash
# Build and run TrackPad using Swift Package Manager
# Requirements: macOS 13+ with Xcode Command Line Tools installed
#
# Usage:
#   chmod +x build_and_run.sh
#   ./build_and_run.sh

set -e

echo "Building TrackPad..."
swift build -c debug

echo ""
echo "Running TrackPad..."
.build/debug/TrackPad
