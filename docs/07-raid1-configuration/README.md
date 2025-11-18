# RAID1 Configuration

Настройка программного RAID1 для двух дисков.

## Обзор

Для установки Debian 12 с программным RAID1 используется отдельный provisioning шаблон.

## Требования

- Два диска одинакового размера (например, 240GB каждый)
- Отключенное шифрование (LUKS не используется)

## Настройка шаблона

Создайте новый provisioning шаблон для RAID1 или модифицируйте Template 196:

1. Отключите LUKS (`crypto_passphrase` не установлен)
2. Используйте `expert_recipe` для RAID1:

```erb
d-i partman-auto/method string raid
d-i partman-auto/disk string /dev/sda /dev/sdb
d-i partman-auto-raid/recipe string \
  1 2 0 ext4 /boot /dev/sda#1 /dev/sdb#1 . \
  1 2 0 ext4 / /dev/sda#2 /dev/sdb#2 . \
  1 2 0 swap /dev/sda#3 /dev/sdb#3 .
```

## Настройка хоста

Установите переменные хоста:

```
disk_sys = /dev/sda
disk_data = (не используется для RAID1)
data_mount = (не используется для RAID1)
```

## Проверка после установки

```bash
cat /proc/mdstat
lsblk
df -h
```

## См. также

- [Provisioning шаблоны](../05-provisioning-templates/)
- [Управление хостами](../08-host-management/)

