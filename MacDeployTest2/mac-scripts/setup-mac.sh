#!/bin/bash

# Lists your environment and installed signing certificates.
# Run this to verify your setup before running build-and-package.sh.

echo "======================================"
echo "Mac environment check"
echo "======================================"
echo ""

echo ".NET SDK version:"
dotnet --version

echo ""
echo "Xcode Command Line Tools path:"
xcode-select -p

echo ""
echo "Installed signing identities:"
security find-identity -v -p codesigning

echo ""
