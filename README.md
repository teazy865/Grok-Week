# AI Limits

Нативное iOS-приложение для личного трекера лимита Grok. Сайта нет — только SwiftUI, как оболочка у «На улицу», но без WebView.

Репозиторий: https://github.com/teazy865/ai-limits

## Локально

```bash
brew install xcodegen
cd ai-limits
xcodegen generate
open AILimits.xcodeproj
```

В Xcode выбери свою Team и поставь на iPhone.

## GitHub Actions

`.github/workflows/ipa.yml` собирает **unsigned IPA** (как у na-ulitsu) и кладёт артефакт `AILimits-unsigned-ipa`.

Actions → Build IPA → Run workflow.
