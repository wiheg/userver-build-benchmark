# userver build benchmark

Замеры времени сборки сервиса на `userver` через `ClangBuildAnalyzer` и проверка оптимизации через прекомпилирование заголовков

## Запуск
```bash
./run.sh
```

## Структура
```text
├── run.sh
├── scripts/
│   ├── run_all.sh
│   ├── setup_tools.sh
│   ├── measure_baseline.sh
│   ├── measure_hypothesis.sh
│   └── compare_results.py
├── results/
└── README.md
```

# Отчёт

## 1. Окружение и железо
* **CPU**: Intel Core Ultra 7 155H (16 ядер / 22 потока: 6P + 8E + 2LPE)
* **ОС**: Windows 11 + WSL2 (Ubuntu 22.04)
* **лимиты**: `--cpus=4 --cpuset-cpus=0-3 --memory=8g --memory-swap=8g`
* **инструменты**: Clang `-ftime-trace`

## 2. Методы
1. Генерация шаблонного сервиса `userver-create-service --grpc --mongo --postgresql benchmark_service`
2. Сборка с `-ftime-trace` через Clang в режиме Release
3. Сбор трейсов с помощью `ClangBuildAnalyzer`
4. Весь процесс автоматизирован через `./run.sh`

## 3. Выводы
1. Фронтенд съедает сильно больше времени, чем бэкенд (примерно 80% от всего времени)
2. Инстанцирование шаблонов:
    * `std::unique_ptr<$>`: **1325 мс** (177 раз)
    * `std::tuple<$>`: **583 мс** (201 раз)
    * `std::unordered_map<$>`: **533 мс** (77 раз)
    * `userver::components::ComponentList::Append<...>`: **393 мс**

## 4. Гипотеза
* **Гипотеза**: добавим прекомпиляцию некоторых хэдеров, это должно исключить множественный разбор дерева инклюдов в
  каждом из файлов и сократить время компиляции
* **Реализация**: в `CMakeLists.txt` добавлена директива `target_precompile_headers`
* **Результаты**:
    * Время парсинга (Frontend) снизилось с 19.5 c до 16.3 c (-16.4%)
    * Парсинг некоторых ключевых файлов также сильно сократился:
        * `src/hello_postgres.cpp`: 1905 ms -> 1019 ms (-886 ms, -46.5%)
        * `src/hello_grpc.cpp`: 1622 ms -> 1030 ms (-592 ms, -36.5%)
        * `src/hello.cpp`: 1055 ms -> <744 ms

* **Итог**: гипотеза подтвердилась. Прекомпилирование заголовков убирает повторный разбор заголовков в прикладных файлах