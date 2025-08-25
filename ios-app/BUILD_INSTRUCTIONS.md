# 📱 Инструкция по сборке iOS приложения Freedom WiFi

## Требования
- macOS 13.0+ (Ventura)
- Xcode 14.0+
- iOS 14.0+ (для запуска)
- Apple Developer Account (для установки на устройство)

## Шаги сборки

### 1. Открытие проекта
```bash
# Открой файл проекта в Xcode
open ios-app/FreedomWiFi.xcodeproj
```

### 2. Настройка Team ID и Bundle Identifier

В Xcode:
1. Выбери проект **FreedomWiFi** в навигаторе
2. Выбери таргет **FreedomWiFi**
3. Перейди на вкладку **"Signing & Capabilities"**
4. Установи свой **Team** (Apple Developer Account)
5. При необходимости измени **Bundle Identifier** на уникальный

### 3. Обновление URL сервера

В файле `ViewController.swift` найди и измени:
```swift
private let serverURL = "https://your-domain.com"
```

### 4. Сборка для симулятора

1. Выбери симулятор в схеме (например, iPhone 15)
2. Нажми **Cmd+R** или кнопку ▶️
3. Приложение запустится в симуляторе

⚠️ **Внимание:** WiFi API не работает в симуляторе!

### 5. Сборка для устройства

1. Подключи iPhone/iPad по USB
2. Выбери свое устройство в схеме
3. Нажми **Cmd+R**
4. При первом запуске: Settings → General → VPN & Device Management → Trust Developer

## Возможные проблемы

### ❌ "Signing for FreedomWiFi requires a development team"
**Решение:** Добавь Apple Developer Account в Xcode Preferences → Accounts

### ❌ "Bundle identifier is not available"
**Решение:** Измени Bundle Identifier на уникальный (например, com.yourname.freedomwifi)

### ❌ "Could not launch app"
**Решение:** Доверься разработчику в настройках устройства

## Архивирование для распространения

### Создание архива:
1. Выбери **"Any iOS Device"** в схеме
2. Product → Archive
3. Дождись завершения архивирования

### Экспорт IPA:
1. В Organizer выбери архив
2. Нажми **"Distribute App"**
3. Выбери метод распространения:
   - **App Store Connect** - для App Store
   - **Ad Hoc** - для тестирования (до 100 устройств)
   - **Enterprise** - для корпоративного распространения
   - **Development** - для разработки

## Тестирование

### На симуляторе:
- Интерфейс работает
- WiFi API недоступно
- Подходит для UI тестов

### На устройстве:
- Полный функционал
- Реальная установка профилей
- Тестирование подключения к WiFi

## Автоматическая сборка

Используй скрипт `build.sh`:
```bash
cd ios-app
chmod +x build.sh
./build.sh
```

## Полезные команды

```bash
# Очистка проекта
# В Xcode: Product → Clean Build Folder (Cmd+Shift+K)

# Сброс симулятора
xcrun simctl erase all

# Просмотр логов устройства
xcrun devicectl list devices
```

## Следующие шаги

1. ✅ Собери и протестируй на устройстве
2. ✅ Настрой правильный URL сервера
3. ✅ Протестируй установку WiFi профилей
4. ✅ Подготовь для распространения через TestFlight или Ad-hoc