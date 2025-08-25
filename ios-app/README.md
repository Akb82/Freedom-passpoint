# Freedom WiFi - iOS App

Нативное iOS приложение для автоматической установки WiFi профилей с использованием NEHotspotConfiguration API.

## Возможности

- ✅ Автоматическая установка WiFi профилей без захода в настройки iPhone
- ✅ Поддержка WPA/WPA2/WPA3 сетей 
- ✅ Поддержка EAP/Enterprise конфигураций
- ✅ Поддержка Passpoint (Hotspot 2.0) профилей
- ✅ Загрузка конфигураций с вашего сервера
- ✅ Простой и понятный интерфейс

## Технические детали

### NEHotspotConfiguration API

Приложение использует современный NEHotspotConfiguration API для:
- Программной установки WiFi конфигураций
- Автоматического подключения к сетям
- Управления EAP настройками
- Поддержки Passpoint профилей

### Поддерживаемые типы конфигураций

1. **WPA/WPA2 сети** - обычные домашние/офисные сети с паролем
2. **EAP сети** - корпоративные сети с логином/паролем 
3. **Passpoint профили** - автоматическое роуминг подключение к сертифицированным точкам доступа

### Парсинг .mobileconfig файлов

Приложение умеет:
- Загружать .mobileconfig файлы с сервера
- Парсить XML структуру профилей
- Извлекать WiFi конфигурации
- Автоматически определять тип подключения

## Сборка проекта

### Требования

- Xcode 14.0+
- iOS 14.0+
- Swift 5.0+

### Установка

1. Откройте `FreedomWiFi.xcodeproj` в Xcode
2. Установите Team ID в настройках проекта
3. Измените URL сервера в `ViewController.swift`:
   ```swift
   private let serverURL = "https://your-repl-domain.repl.co"
   ```
4. Соберите и запустите на устройстве (симулятор не поддерживает WiFi API)

### Настройки проекта

**Info.plist требования:**
- `NSAppTransportSecurity` - разрешение HTTP запросов
- `NSLocationWhenInUseUsageDescription` - для определения WiFi сетей
- `UIRequiredDeviceCapabilities` - wifi capability

**Энтайтлменты:**
- Hotspot Configuration (автоматически добавляется при использовании NEHotspotConfiguration)

## Интеграция с сервером

Приложение работает с Flask сервером и ожидает:

1. **Эндпоинт профилей**: `/hs20/profile.mobileconfig`
   - Возвращает .mobileconfig файл
   - Content-Type: `application/x-apple-aspen-config`

2. **Формат .mobileconfig**:
   - Стандартный Apple Property List формат
   - PayloadType: `com.apple.wifi.managed`
   - Поддержка EAP конфигураций и Passpoint параметров

## Использование

1. Пользователь запускает приложение
2. Автоматически загружается актуальная конфигурация с сервера
3. Отображается информация о сети/профиле
4. Нажатие "Установить" → профиль устанавливается через NEHotspotConfiguration API
5. iPhone автоматически подключается к доступным сетям

## Отладка

Для отладки используйте:
- Xcode консоль для логов установки
- Settings → Wi-Fi для проверки установленных профилей
- Settings → General → VPN & Device Management → для просмотра сертификатов

## Распространение

- **Development**: сборка через Xcode для тестирования
- **Ad-hoc**: распространение через TestFlight или Enterprise
- **App Store**: публикация через App Store Connect (требует review)

Приложение готово к использованию и значительно упрощает процесс установки WiFi профилей для пользователей!