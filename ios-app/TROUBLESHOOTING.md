# 🔧 Решение проблем iOS сборки

## Частые ошибки и решения

### 1. Проблемы с подписью кода

#### ❌ "Signing for FreedomWiFi requires a development team"
```
Решение:
1. Xcode → Preferences → Accounts
2. Добавь Apple ID (бесплатный аккаунт подойдет)
3. В проекте выбери свой Team
```

#### ❌ "Provisioning profile doesn't match"
```
Решение:
1. Измени Bundle Identifier на уникальный
2. Или удали старые профили: ~/Library/MobileDevice/Provisioning Profiles
```

### 2. Проблемы сборки

#### ❌ "Build input file cannot be found"
```
Решение:
1. Product → Clean Build Folder (Cmd+Shift+K)
2. Перезапусти Xcode
3. Пересобери проект
```

#### ❌ "Module not found"
```
Решение:
1. Проверь что все файлы добавлены в таргет
2. Build Settings → Swift Compiler - Search Paths
```

### 3. Проблемы с устройством

#### ❌ "Could not launch app"
```
Решение:
1. Settings → General → VPN & Device Management
2. Найди свой Developer App
3. Нажми Trust
```

#### ❌ "This app cannot be installed because its integrity could not be verified"
```
Решение:
1. Пересобери с правильным сертификатом
2. Проверь что устройство добавлено в Provisioning Profile
```

### 4. WiFi API проблемы

#### ❌ "NEHotspotConfiguration not working"
```
Причины:
- Работает только на реальном устройстве
- Требует iOS 11.0+
- Нужны правильные энтайтлменты
```

#### ❌ "Configuration failed with error"
```
Проверь:
- Правильность SSID и пароля
- Формат EAP настроек
- Сертификаты в профиле
```

## Отладка

### Логи в Xcode
```swift
// Добавь в код для отладки
print("Debug: \(variable)")
os_log("Network error: %@", log: .default, type: .error, error.localizedDescription)
```

### Консоль устройства
```bash
# Просмотр логов устройства
xcrun devicectl list devices
xcrun devicectl device logs --device [DEVICE_ID]
```

### Network Link Conditioner
```
1. Settings → Developer → Network Link Conditioner
2. Включи для тестирования медленной сети
```

## Оптимизация сборки

### Ускорение сборки
```
Build Settings:
- COMPILER_INDEX_STORE_ENABLE = NO
- DEBUG_INFORMATION_FORMAT = dwarf (для Debug)
- SWIFT_COMPILATION_MODE = Incremental (для Debug)
```

### Уменьшение размера приложения
```
Build Settings:
- SWIFT_COMPILATION_MODE = wholemodule (для Release)
- DEAD_CODE_STRIPPING = YES
- STRIP_INSTALLED_PRODUCT = YES
```

## Полезные ресурсы

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [NEHotspotConfiguration Guide](https://developer.apple.com/documentation/networkextension/nehotspotconfiguration)
- [iOS App Distribution Guide](https://developer.apple.com/library/archive/documentation/IDEs/Conceptual/AppDistributionGuide/)