#!/bin/bash
set -euo pipefail
DEST=AILimits/Assets.xcassets/AppIcon.appiconset
mkdir -p "$DEST"
for name in AppIcon AppIcon-dark AppIcon-tinted; do
  if [ -f "scripts/${name}.png.b64" ]; then
    base64 -d "scripts/${name}.png.b64" > "$DEST/${name}.png"
  fi
done
ls -lh "$DEST"
