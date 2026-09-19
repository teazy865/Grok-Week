# Grok Week

На русском на телефоне: **Неделя Grok**.

iOS-приложение и виджет: сколько осталось недельного пула SuperGrok.

**Не является продуктом xAI.** Неофициальный личный трекер. API может измениться без предупреждения.

## Что умеет

- вход через device code на `auth.x.ai` (как Grok CLI)
- процент использования и дата сброса
- виджеты small / medium, обновление раз в 5 минут и кнопка refresh
- токены только в Keychain, не в репозитории

Текущая версия: **0.6.1 (10)**

## Установка через GBox

1. Открой [Actions → Build IPA](https://github.com/teazy865/ai-limits/actions/workflows/ipa.yml).
2. В последнем успешном прогоне скачай artifact `AILimits-unsigned-ipa`.
3. Подпиши IPA в GBox и установи.
4. Открой приложение → **Войти в xAI** → введи код на странице xAI.
5. Добавь виджет **Неделя Grok** на домашний экран.

Можно ставить поверх старой сборки с тем же bundle id `com.teazy.ailimits`. После обновления виджет лучше снять и поставить заново.

## Сборка из Xcode

```bash
git clone https://github.com/teazy865/ai-limits.git
cd ai-limits
brew install xcodegen
xcodegen generate
open AILimits.xcodeproj
```

Включи App Group `group.com.teazy.ailimits` у приложения и виджета, выбери свою Team.

## Безопасность

- В репозитории нет access/refresh-токенов.
- OAuth `client_id` — public client (device flow, без secret).
- Не публикуй скриншоты с device-code и сессией.

## Дисклеймер

Grok, SuperGrok и xAI — торговые марки соответствующих правообладателей. Этот проект с ними не связан. Используй на свой риск.
