#!/bin/bash

# Deep Link Testing Script for Banking App
# Usage: ./test-deep-links.sh

echo "🔗 Banking App Deep Link Tester"
echo "================================"
echo ""
echo "⚠️  Make sure the app is running on the simulator first!"
echo ""
echo "Press Enter to continue..."
read

echo ""
echo "Testing Tab Navigation..."
echo ""

echo "1️⃣  Opening Home tab..."
xcrun simctl openurl booted "bankapp:///home"
sleep 2

echo "2️⃣  Opening Accounts tab..."
xcrun simctl openurl booted "bankapp:///accounts"
sleep 2

echo "3️⃣  Opening Transfer tab..."
xcrun simctl openurl booted "bankapp:///transfer"
sleep 2

echo "4️⃣  Opening Cards tab..."
xcrun simctl openurl booted "bankapp:///cards"
sleep 2

echo "5️⃣  Opening More tab..."
xcrun simctl openurl booted "bankapp:///more"
sleep 2

echo ""
echo "Testing Deep Routes (requires Epic 2+ implementation)..."
echo ""

echo "6️⃣  Account detail route..."
xcrun simctl openurl booted "bankapp:///accounts/ACC123"
sleep 2

echo "7️⃣  Account transactions route..."
xcrun simctl openurl booted "bankapp:///accounts/ACC123/transactions"
sleep 2

echo "8️⃣  Transfer receipt route..."
xcrun simctl openurl booted "bankapp:///transfer/receipt/TXN456"
sleep 2

echo "9️⃣  Card detail route..."
xcrun simctl openurl booted "bankapp:///cards/CARD789"
sleep 2

echo ""
echo "Testing Error Handling..."
echo ""

echo "🔟  Invalid route (should log error, not crash)..."
xcrun simctl openurl booted "bankapp:///invalid"
sleep 2

echo ""
echo "✅ Testing complete!"
echo ""
echo "Expected Behavior:"
echo "  - App should open for each URL"
echo "  - Until Epic 2 is complete, you'll see placeholder auth screens"
echo "  - Deep links are stored and will be processed after authentication"
echo "  - Invalid URLs should log an error without crashing"
echo ""
