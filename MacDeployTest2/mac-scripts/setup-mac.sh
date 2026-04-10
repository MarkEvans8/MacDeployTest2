#!/bin/bash

echo "======================================"
echo "Mac Setup Script for .pkg Creation"
echo "======================================"
echo ""

# Check if Xcode Command Line Tools are installed
echo "Checking for Xcode Command Line Tools..."
if xcode-select -p &> /dev/null; then
    echo "âœ“ Xcode Command Line Tools are already installed"
else
    echo "Installing Xcode Command Line Tools..."
    echo "A dialog will appear - click Install and wait for it to complete"
    xcode-select --install
    echo "After installation completes, run this script again."
    exit 1
fi

echo ""
echo "Checking for signing certificates..."
echo ""
echo "Developer ID Application certificates (for signing the app):"
security find-identity -v -p codesigning | grep "Developer ID Application"

echo ""
echo "Developer ID Installer certificates (for signing the .pkg):"
security find-identity -v -p codesigning | grep "Developer ID Installer"

echo ""
echo "======================================"
echo "Setup Complete!"
echo "======================================"
echo ""
echo "NEXT STEPS:"
echo "1. If you don't see certificates above, you need to:"
echo "   - Go to https://developer.apple.com/account/resources/certificates"
echo "   - Create 'Developer ID Application' and 'Developer ID Installer' certificates"
echo "   - Download the .cer files"
echo "   - Double-click them on this Mac to install"
echo ""
echo "2. Once certificates are installed, you can build and package your app!"
echo ""
