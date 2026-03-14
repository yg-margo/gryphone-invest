[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2.svg)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-18%2B-339933.svg)](https://nodejs.org)
[![iOS](https://img.shields.io/badge/iOS-supported-000000.svg)](https://developer.apple.com/ios/)
[![Android](https://img.shields.io/badge/Android-supported-3DDC84.svg)](https://developer.android.com)


<p align="center">
  <img src="assets/icons/app_icon.png" alt="App Icon" width="120" />
</p>

# Gryphone Invest

Мобильный симулятор инвестиций на Flutter. Симулируй сделки, изучай прогнозы на основе ИИ и тестируй стратегии — без риска реальных денег.

> Только для образовательных целей. Не является финансовым советом.

---

## Содержание

- [Обзор](#обзор)
- [Функциональность](#функциональность)
- [Быстрый старт](#быстрый-старт)
- [Конфигурация окружения](#конфигурация-окружения)
- [Структура проекта](#структура-проекта)
- [Основные зависимости](#основные-зависимости)
- [Backend API](#backend-api)

---

## Обзор

Gryphone Invest выдаёт пользователю виртуальный портфель в \$100 000 для практики инвестирования. Живые цены загружаются с Yahoo Finance, а бэктестинг прогоняет реальные исторические данные через классические торговые стратегии. Главная фишка - использование ИИ в инвестициях: AI выдает предсказания на основе новостей, данных и предагает купить пользователю подходящее под портфель количество акций. Купить просто - свайпай предложения, как в Tinder, все нужное сразу попадет в портфель!

Приложение поддерживает два языка (русский и английский) и две темы (светлую и тёмную) — оба параметра сохраняются между сессиями.

**WARNING:** Нейросеть пока не написана, будет реализована в процессе финала

### Web-сервис: https://yg-margo.github.io/gryphone-invest/

### Android .apk: тут будет ссылка

### iPhone .ipa: только эмулятор .xcode на MAC, так как без релиза в App Store или подписанного под устройство .ipa запуск не возможен

---

## Функциональность

### Авторизация

- Регистрация с именем, фамилией, логином, email и паролем
- Вход по JWT-токену, сохраняемому в SharedPreferences
- Восстановление пароля по email
- Автоматическое восстановление сессии при запуске приложения

---

### Главная

- Общая стоимость портфеля с приростом и доходностью за всё время
- Бейдж «Онлайн» с автообновлением каждые 60 секунд
- Мини-график доходности портфеля (1Н / 1М / 3М)
- Статистика: общая прибыль, доходность %, доступные наличные, количество позиций
- Список рынка с живыми ценами и переходом к детальному экрану по нажатию


---

### Портфель

- Столбчатая диаграмма распределения с цветовой легендой по позициям
- Сводная статистика: вложено, рыночная стоимость, П/У
- Тайлы позиций: количество акций, средняя цена, текущая цена, прибыль/убыток
- Диалог продажи с подтверждением и разбивкой П/У
- Добавление позиции с быстрым выбором объёма (25% / 50% / 75% / Макс от доступных средств)
- Диалог сброса портфеля для возврата \$100 000


---

### Обзор

Экран с двумя вкладками: новости и ИИ-прогнозы.

**Вкладка «Новости»**

- Статьи загружаются с бэкенда на выбранном языке
- Изображение, бейдж источника, относительная метка времени, заголовок, описание
- Нажатие открывает статью во внешнем браузере
- Потяни для обновления, кнопка повтора при ошибке


**Вкладка «ИИ Прогнозы»**

- Интерфейс карточек со свайпом: вправо — купить, влево — пропустить
- Карточки показывают текущую цену, целевую цену, ожидаемую доходность, рекомендуемое количество, уверенность и обоснование
- Селектор горизонта: 7 дней / 30 дней / 90 дней
- Отображаются прогнозы AI с положительной доходностью
- Покупка списывает средства и добавляет позицию в портфель


---

### Бэктестинг

- Выбор стратегии: Пересечение скользящих, RSI Моментум, Полосы Боллинджера, Купить и держать, Возврат к среднему
- Выбор тикера из списка живых акций
- Период: 30 / 60 / 90 дней
- Ввод начального капитала
- Результаты: общая доходность, годовая доходность, максимальная просадка, коэффициент Шарпа, винрейт, количество сделок
- График кривой доходности с интерактивными подсказками
- Список торговых сигналов (до 10 последних)
- Реальные исторические данные загружаются с Yahoo Finance


---

### Профиль и настройки

- Выбор аватара (камера или галерея, удаление)
- Редактирование имени и фамилии прямо на экране
- Переключение тёмной/светлой темы с сохранением
- Переключатель языка (RU / EN) с сохранением
- Сброс портфеля из настроек
- Версия приложения и дисклеймер
- Выход из аккаунта с диалогом подтверждения

---

## Быстрый старт

### Требования

- Flutter SDK 3.x
- Dart 3.x
- Запущенный бэкенд (см. [Backend API](#backend-api))

### Установка

git clone https://github.com/your-org/gryphone-invest.git
cd gryphone-invest
flutter pub get

### Запуск

# Режим разработки — использует localhost:3000
flutter run

# С кастомным URL бэкенда
flutter run --dart-define=API_BASE_URL=https://your-api.example.com/api/v1

### Сборка

# Android
flutter build apk --release --dart-define=API_BASE_URL=https://your-api.example.com/api/v1

# iOS
flutter build ipa --release --dart-define=API_BASE_URL=https://your-api.example.com/api/v1

---

## Конфигурация окружения

URL бэкенда передаётся в момент сборки через Dart define:

API_BASE_URL=https://your-api.example.com/api/v1

Если переменная не задана, приложение по умолчанию использует `http://localhost:3000/api/v1`.

Веб-сборки направляют запросы к Yahoo Finance через прокси на бэкенде (`/yahoo/chart/:symbol`, `/yahoo/quote`, `/yahoo/company/:symbol`) для обхода CORS. Нативные сборки обращаются к Yahoo Finance напрямую.

---

## Структура проекта
```
lib/
  core/
    constants/
      app_constants.dart      Константы приложения (версия, стартовый капитал, список стратегий)
      app_strings.dart        Все строки интерфейса на русском и английском
    theme/
      app_theme.dart          AppColors, светлая тема, тёмная тема
    utils/
      formatters.dart         Форматтеры валют, процентов, дат, компактных чисел
  data/
    models/
      backtest_result.dart
      news_article.dart
      portfolio.dart
      position.dart
      stock.dart
      stock_detail.dart
    providers/
      auth_provider.dart
      locale_provider.dart
      market_provider.dart
      portfolio_provider.dart
      theme_provider.dart
    services/
      ai_prediction_service.dart
      api/
        api_config.dart
      auth_service.dart
      backtest_service.dart
      company_descriptions.dart
      market_data_service.dart
      news_service.dart
      portfolio_api_service.dart
      yahoo_finance_service.dart
  presentation/
    screens/
      auth/
        auth_widgets.dart
        forgot_password_screen.dart
        login_screen.dart
        register_screen.dart
      backtesting/
        backtest_screen.dart
      discover/
        discover_screen.dart
      home/
        home_screen.dart
      portfolio/
        add_position_screen.dart
        portfolio_screen.dart
      predictions/
        models/
          stock_offer.dart
        widgets/
          horizon_selector.dart
          swipe_offer_stack.dart
        predictions_screen.dart
      profile/
        profile_screen.dart
      stock/
        stock_detail_screen.dart
      main_screen.dart
    widgets/
      portfolio_chart.dart
      position_tile.dart
      prediction_card.dart
      stat_card.dart
      stock_mini_chart.dart
  app.dart
  main.dart
```
---

## Основные зависимости

| Пакет | Назначение |
|---|---|
| provider | Управление состоянием |
| fl_chart | Линейные графики, кривые доходности |
| shared_preferences | Локальное персистентное хранилище |
| http | HTTP-клиент |
| google_fonts | Шрифт Inter |
| intl | Форматирование чисел и дат |
| image_picker | Выбор аватара из камеры или галереи |
| url_launcher | Открытие новостей в браузере |
| uuid | Уникальные идентификаторы для объектов Position |
| flutter_localizations | Material-делегаты локализации |

---

## Backend API

Приложение ожидает REST-бэкенд по настроенному базовому URL со следующими эндпоинтами:

| Метод | Путь | Описание |
|---|---|---|
| POST | /auth/login | Возвращает JWT-токен и объект пользователя |
| POST | /auth/register | Создаёт аккаунт, возвращает токен |
| POST | /auth/forgot-password | Отправляет письмо для сброса пароля |
| POST | /auth/reset-password | Применяет новый пароль по токену |
| GET | /portfolio | Загрузить портфель авторизованного пользователя |
| PUT | /portfolio | Сохранить портфель (наличные + позиции) |
| POST | /portfolio/reset | Сбросить портфель до начальных значений |
| GET | /news?lang=ru\|en | Получить список новостных статей |
| GET | /yahoo/chart/:symbol | Прокси графика Yahoo Finance (только веб) |
| GET | /yahoo/quote | Прокси котировок Yahoo Finance (только веб) |
| GET | /yahoo/company/:symbol | Прокси данных о компании Yahoo Finance (только веб) |

Все защищённые эндпоинты требуют заголовок `Authorization: Bearer ,[object Object]`
