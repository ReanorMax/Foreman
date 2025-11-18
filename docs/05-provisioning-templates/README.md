# Provisioning Templates - Шаблоны установки

Документация по provisioning шаблонам для автоматической установки Debian 12.

## Обзор

Provisioning шаблоны определяют процесс автоматической установки операционной системы на целевые хосты. В нашей конфигурации используются шаблоны для:

- **LUKS/TPM шифрования**: Полнодисковое шифрование с автоматической разблокировкой через TPM2
- **RAID1**: Программный RAID1 для двух дисков
- **Многодисковая конфигурация**: Системный диск + диск данных с автоматическим монтированием

## Template 196: Preseed via PTable (no partman)

Основной шаблон для установки Debian 12 с поддержкой LUKS/TPM шифрования.

### Расположение

См. полный шаблон: [Template_196_Preseed_via_PTable.erb](Template_196_Preseed_via_PTable.erb)

### Требуемые переменные хоста

#### Обязательные переменные:

- `disk_sys`: Системный диск (например, `/dev/sda` или `/dev/disk/by-id/wwn-0xEXAMPLEc500a1234567`)
- `disk_data`: Диск данных (например, `/dev/sdb` или `/dev/disk/by-id/wwn-0xEXAMPLEc500b1234567`)
- `data_mount`: Точка монтирования диска данных (например, `/home/storage/local`)

#### Опциональные переменные (для LUKS):

- `crypto_passphrase`: Парольная фраза для LUKS (если используется шифрование)
- `var_size`: Размер `/var` раздела (по умолчанию `40G`)
- `root_size`: Размер корневого раздела (по умолчанию `100G`)
- `home_size`: Размер `/home` раздела (по умолчанию `20G`)
- `swap_size`: Размер `swap` раздела (по умолчанию `2G`)

### Настройка шаблона в Foreman

1. Перейдите в **Настройка → Provisioning шаблоны**
2. Найдите шаблон `Preseed via PTable (no partman)` (ID: 196)
3. Убедитесь, что шаблон связан с:
   - **OS**: `Debian 12.12`
   - **Architecture**: `x86_64`
   - **Partition Table**: `Simple Debian 12 (no crypto)` или `Simple Debian 12 LUKS`

4. Скопируйте содержимое из [Template_196_Preseed_via_PTable.erb](Template_196_Preseed_via_PTable.erb) в редактор шаблона

### Настройка хоста

1. Перейдите в **Узлы → Ваш хост → Изменить**
2. В разделе **Параметры** добавьте требуемые переменные:

```
disk_sys = /dev/disk/by-id/wwn-0xEXAMPLEc500a1234567
disk_data = /dev/disk/by-id/wwn-0xEXAMPLEc500b1234567
data_mount = /home/storage/local
crypto_passphrase = ваш_секретный_пароль
```

3. Сохраните изменения

### Процесс установки

1. **Выбор диска**: Шаблон автоматически выбирает системный диск на основе `disk_sys` или определяет самый маленький диск
2. **Разметка диска**:
   - Если `crypto_passphrase` установлен: создается LUKS контейнер с LVM внутри
   - Если нет: создается обычная разметка
3. **Создание разделов**:
   - `/boot`: EFI раздел
   - `/`: Корневой раздел (100GB по умолчанию)
   - `/home`: Домашний раздел (20GB по умолчанию)
   - `/var`: Переменный раздел (40GB, создается через `late_command`)
   - `swap`: Раздел подкачки (2GB по умолчанию)
4. **Шифрование** (если включено):
   - LUKS контейнер создается с парольной фразой
   - TPM2 автоматически регистрируется через `luks_tpm_enroll.sh`
5. **Монтирование диска данных**:
   - Диск данных автоматически размечается, форматируется и монтируется через `mount_disk.sh`

### Скрипты, используемые шаблоном

1. **create_var_lv.sh**: Создание `/var` логического тома (если используется LVM)
   - Расположение: `http://192.168.0.104:8081/repository/artifacts-local/usr/share/foreman/public/create_var_lv.sh`
   - См. [configs/scripts/create_var_lv.sh](../../configs/scripts/create_var_lv.sh)

2. **luks_tpm_enroll.sh**: Регистрация LUKS раздела в TPM2
   - Расположение: `http://192.168.0.104:8081/repository/artifacts-local/usr/share/foreman/public/luks_tpm_enroll.sh`
   - См. [configs/scripts/luks_tpm_enroll.sh](../../configs/scripts/luks_tpm_enroll.sh)

3. **mount_disk.sh**: Разметка, форматирование и монтирование диска данных
   - Расположение: `http://192.168.0.104:8081/repository/artifacts-local/usr/share/foreman/public/mount_disk.sh`
   - См. [configs/scripts/mount_disk.sh](../../configs/scripts/mount_disk.sh)

## Альтернативные шаблоны

### Template для RAID1

Для установки с программным RAID1 используется отдельный шаблон. См. [docs/07-raid1-configuration/](../07-raid1-configuration/).

## Вспомогательные функции Ruby

Шаблон использует следующие вспомогательные функции:

- `as_device(dev)`: Преобразование пути диска в корректный формат
- `str_param(name, default)`: Получение строкового параметра хоста
- `int_param(name, default)`: Получение числового параметра хоста

## Решение проблем

### Хост не загружается с шаблона

1. Убедитесь, что шаблон связан с правильной OS и Architecture
2. Проверьте, что PXE loader настроен правильно (см. [iPXE загрузка](../10-ipxe-boot/))

### Диски перепутываются

1. Используйте стабильные `by-id` пути вместо `/dev/sda`
2. Проверьте переменную `disk_sys` в параметрах хоста
3. Убедитесь, что `partman/early_command` корректно выбирает диск

### Шифрование не работает

1. Убедитесь, что `crypto_passphrase` установлен в параметрах хоста
2. Проверьте, что скрипт `luks_tpm_enroll.sh` доступен по URL
3. Проверьте логи: `/var/log/tpm.log` и `/var/log/var_creation.log`

### /var раздел не создается

1. Убедитесь, что используется LVM (LUKS метод)
2. Проверьте, что скрипт `create_var_lv.sh` доступен по URL
3. Проверьте логи: `/var/log/var_creation.log`

## См. также

- [LUKS/TPM шифрование](../06-encryption-luks-tpm/)
- [RAID1 конфигурация](../07-raid1-configuration/)
- [Управление хостами](../08-host-management/)
- [Решение проблем](../11-troubleshooting/)

