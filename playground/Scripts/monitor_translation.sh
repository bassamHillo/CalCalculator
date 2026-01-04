#!/bin/bash
# Quick status check - runs fast, doesn't get stuck
cd /Users/zoharbuchris/Documents/CalCalculator/playground
./check_translation_status.sh
echo ""
echo "To see live progress: tail -f translation_output.log"
echo "To check if still running: ps aux | grep translate_all"
