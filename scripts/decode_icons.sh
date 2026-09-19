#!/bin/bash
set -euo pipefail
python3 scripts/generate_appicon.py
ls -lh AILimits/Assets.xcassets/AppIcon.appiconset/
