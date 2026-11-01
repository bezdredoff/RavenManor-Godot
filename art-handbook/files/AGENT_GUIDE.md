# Raven Art Handbook — контракт для человека и AI-агента

Версия 1 · снимок 2026-11-01. Машинная точка входа: `catalog.json`; исходные записи — `data/raven/production/art_workflow_handbook.json`, `content.json`, `files/environment.json`. Книга описывает уже полученные результаты, а не разрешение менять принятый арт.

## Что считается доказательством

1. Embedded API/workflow принятого исходного PNG.
2. Отдельный executed API + success history, когда PNG не содержит workflow (четыре позы Эвелин).
3. Сохранённая UI-сессия: состояние интерфейса, не гарантия точного последнего запуска. Для ClothesDesigner UI синхронизирован с API neutral PNG; сам API авторитетнее.
4. Сохранённые требования/намерение для ChatGPT-фонов. Verbatim prompt и внутренние seed/sampler/model не записаны и остаются `null`.
5. Явно обозначенная реконструкция (ранний Hall map pilot). Никогда не выдавать её за оригинальный запрос.

`exact_saved_run` означает найденный исторический запуск с этим результатом. Он не гарантирует побайтовую идентичность новой генерации на другом драйвере, GPU или версии узлов. Снимок установленной системы получен при документировании; это не ретроспективный lockfile для каждого старого запуска.

Исходные производственные runners приложены в `files/scripts/reference/` для аудита, а не для запуска в новом проекте без адаптации. Они содержат исторические абсолютные пути и логику resume. `prepare_*` могли сохраниться до поздних ручных исправлений и сбрасывать manifests; не пересоздавать принятую партию вслепую. Приоритет у API принятого PNG и его маски.

## Как найти рецепт

Найти `assets[].id`, сверить SHA текущего опубликованного изображения, открыть `recipeId`. Для персонажа пройти `chain`: identity → dress → нужная эмоция/поза/inpaint. `recipes[].parameters` — краткая выжимка; `settings` и скачиваемый JSON содержат полный снимок, включая неактивные defaults. `artifacts` содержат относительный путь и SHA. Внешние репозиторные ссылки разрешаются относительно зафиксированного `baselineCommit`.

Книга покрывает все 101 raster-файл под `assets/` на baseline и отдельно 52 исторических wall-candidate задания. Основной VN-набор: 62 персонажа + 26 фонов. Архив, технические placeholders и кандидаты не становятся принятыми из-за включения в книгу. SVG интерфейса и производные зеркала Builder — кодовые ресурсы; см. additionalPipelines.

## Система и необходимые файлы

Рабочая среда: Raven sandbox на D:, `127.0.0.1:8189`; core, user state, input/output/temp/cache раздельны. Python берётся из `D:\AI\ComfyUI-Desktop\.venv`, модели — физически из `D:\AI\ComfyUI-Desktop\models` через YAML. Не восстанавливать зависимость от `C:\StableDiffusion` junctions.

Сверить Python/PyTorch/CUDA/driver, core commit, VNCCS commit и source-tree hashes пакетов в environment.json. VNCCS-utils 0.7.0 в этом snapshot не имеет доступного `.git`: commit неизвестен, измерен source-tree SHA. Не заменять эту неопределённость предположением о latest. Модели сверять по filename + size + SHA-256; веса не включены в книгу. QI2 entries из Control Center приложены отдельно; это фрагмент каталога, его нельзя вслепую записывать поверх всего Control Center.

Минимум для native inpaint: Qwen Image 2.1 INT8 ConvRot, Qwen3VL 8B INT8 ConvRot, QI2 VAE bf16 и QwenImage21Cache. Для эмоций нужен Viggle 6-step adapter, для поз — PoseStudioV2 helper и SeedVR2/ema VAE. SAM3/SAM3D/DWPose использовались в исследованиях; они не объявлены обязательными для каждого принятого native-RGBA рецепта.

Локальный `RavenCleanNativeAlpha` находится в files/custom_nodes/raven_pose_export/__init__.py. После установки custom node перезапустить нужный ComfyUI, проверить `/object_info`. Пакеты, установленные рядом с нужным узлом, не обязательно исполнялись в данном рецепте.

## Порядок повторения

1. Работать в копии проекта и отдельном пространстве имён VNCCS. Не перезаписывать принятые персонажи, костюмы, PNG и уже сохранённые генерации.
2. Установить точно нужные модели/узлы и проверить их доступность. Не загружать модели из неактивных Anima/Illustrious defaults внутри JSON.
3. Identity: открыть соответствующий UI CharacterCreatorV2; проверить возраст, лицо, тело, волосы, глаза, Watercolor Anime Illustration, aesthetics и negative. Создать отдельную библиотечную фигуру. Базовые неодетые изображения в публичную книгу не включены.
4. ClothesDesigner: создать костюм у персонажа в библиотеке, заполнить costume_info и запустить preview. Граф, полученный из neutral PNG, является авторитетным API. Требуются существующие Naked/Original и costume slot.
5. Эмоции: добавить определения из `custom_emotions.json` через штатный интерфейс VNCCS, выбрать тот же costume. В настоящем запуске включён Viggle Turbo: 6 steps, CFG 1, strength 1, seed 0. Не подставлять сюда 25/3 из другого этапа. Сохранять output 0 целиком; output 1 — только лицо.
6. Позы Эвелин: исходный UI использует live Pose Studio. `pose_data` сохранён, но server-only queue без browser capture не гарантирует тот же манекен. Replay API заменяет Pose Studio его фактическим PNG; это подготовленная адаптация, не новый проверенный GPU-прогон. Output — 2048×3614 после SeedVR2.
7. Inpaint: скопировать inputs из рецепта в `ComfyUI/input/RavenHandbook/`, загрузить replay API. Crop/mask индивидуальны. Сначала выполнить preflight; затем один кадр и визуальная проверка, после этого партия по очереди. Не считать UI-поля маски универсальными для другого силуэта.
8. После inpaint восстановить исходные RGBA вне области ненулевой маски через restore_protected_pixels.py. У LoadImage MASK и JoinImageWithAlpha уже согласована инверсия; дополнительный InvertMask не нужен. Чистить альфу только у нового фрагмента.
9. Проверить лицо, контур волос/пальцев/предмета, отсутствие лишних рук, края crop/mask, непрозрачность одежды, полный рост, идентичность и отсутствие scale jitter. Только владелец принимает новый результат.
10. Экспорт: персонажи — native-size lossless WebP с точным RGBA сравнением; фоны — 1080×1920, RGB WebP q91/method6. Не менять канонические IDs/сценарий ради арта. Обновить каталог, hashes, STATUS и production_progress в том же PR; выполнить проектные checks и визуальный QA.

## Настройки, которые легко прочитать неправильно

- В генераторе поз `inherit_pipe=true`: активные steps/CFG берутся из Control Center (25/3), а не из сохранённых fallback 20/1. Seed Control Center proxy по коду равен 0; наследование SeedVR также не равняется сохранённому fallback seed 42.
- QI2 target_size используется как scale/megapixels, не как гарантированная высота картинки. Записывать реальные width/height результата.
- Native poses получают RGB-манекен как image 1 и персонажа как image 2. Legacy `weight1/2/3` не читаются этой веткой. Helper LoRA накладывается отдельно (default strength 1).
- У QI2 pose encoder negative по этому code snapshot пустой. ClothesDesigner строит собственный negative; character_info.negative_prompt в его состоянии не означает автоматическую передачу. Эмоции Turbo применяют positive-only BasicGuider. В native inpaint negative явно задан и используется с CFG 3.
- ClothesDesigner по умолчанию включает QI2 edit prompt enhancement, если в gen_settings явно не указано false. При наличии только входных полей и шаблона rewriter нельзя выдумать точный сгенерированный им финальный текст. Сохранять это как известный пробел.
- Сохранённый успех с одним предметом не доказывает пригодность той же маски для большого ящика, вытянутого пальца или поднятого локтя.

## Ограничения и архив

Состояния с разными предметами и характерными жестами — отдельные изображения, не готовые анимации. Моргание, рот, промежуточные keyframes и чиби-персонажи ещё не произведены. Параметры экспериментов с 0.8 и усилением «акварельности» не являются автоматически текущими финальными настройками.

52 Flux-wall jobs имеют точные prompts/seeds и template, но остаются pending review. Старые Hall map prompts явно реконструированы. Старые VN-портреты superseded. Оноэ — внешний технический placeholder. Полная книга не должна автоматически загружать новые модели, ставить узлы, запускать GPU, менять VNCCS-библиотеку или публиковать изменённый арт.

## Сторонние материалы

Три prompt-template файла взяты из VNCCS d74c2fc833f13842d39d2a2261489ea08ba3f6b2 (AHEKOT/ComfyUI_VNCCS). Их MIT license сохранена в files/licenses/VNCCS_LICENSE.txt. Модели и полные third-party packs не распространяются.
