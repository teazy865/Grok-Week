# AI Limits

Нативное iOS-приложение: недельный пул SuperGrok и виджет.

Вход — device code на auth.x.ai (как Grok CLI). Цифры — `GET cli-chat-proxy.grok.com/v1/billing?format=credits` (`creditUsagePercent`). Токен только в Keychain.

Репо: https://github.com/teazy865/ai-limits

## Сборка для GBox

```bash
git clone https://github.com/teazy865/ai-limits.git
cd ai-limits
brew install xcodegen
xcodegen generate
open AILimits.xcodeproj
```

В Xcode: своя Team, включи App Group `group.com.teazy.ailimits` у приложения и виджета. Либо собери IPA акшеном и подпиши в GBox.

## Как пользоваться

1. Открой приложение → **Войти в xAI**.
2. Откроется страница xAI. Введи показанный код.
3. Дождись «Готово» — кольцо покажет % использования за неделю и сколько осталось.
4. Добавь виджет **Grok Usage** на домашний экран.

Неофициальный endpoint CLI. xAI может его сменить.
