# Host Management - Управление хостами

Управление хостами в Foreman.

## Создание хоста

1. Перейдите в **Узлы → Создать узел**
2. Заполните параметры:
   - **Имя**: `host2.example.com.local`
   - **MAC адрес**: `11:22:33:44:55:66`
   - **IPv4 адрес**: `192.168.0.251`
   - **Подсеть**: `Internal Network`
   - **Smart Proxy**: Выберите ваш Smart Proxy
   - **Операционная система**: `Debian 12.12`
   - **Архитектура**: `x86_64`
   - **Partition Table**: `Simple Debian 12 LUKS` (или `Simple Debian 12 (no crypto)`)
   - **PXE Loader**: `iPXE UEFI HTTP`

## Настройка переменных хоста

В разделе **Параметры** добавьте требуемые переменные:

### Для LUKS/TPM шифрования:

```
disk_sys = /dev/disk/by-id/wwn-0xEXAMPLEc500a1234567
disk_data = /dev/disk/by-id/wwn-0xEXAMPLEc500b1234567
data_mount = /home/storage/local
crypto_passphrase = ваш_секретный_пароль
var_size = 40G
root_size = 100G
home_size = 20G
swap_size = 2G
```

### Для RAID1:

```
disk_sys = /dev/sda
```

## Группы узлов (Hostgroups)

### Создание группы

1. Перейдите в **Настройка → Группы узлов → Создать группу**
2. Заполните:
   - **Имя**: `Debian 12 LUKS RAID1`
   - **Операционная система**: `Debian 12.12`
   - **Архитектура**: `x86_64`
   - **Partition Table**: `Simple Debian 12 LUKS`

3. В разделе **Параметры** добавьте общие переменные для всех хостов в группе

### Привязка хоста к группе

1. Перейдите в **Узлы → Ваш хост → Изменить**
2. Выберите **Группа узлов**: `Debian 12 LUKS RAID1`
3. Сохраните

## Режимы хоста

- **Build**: Хост готов к установке/переустановке
- **Normal**: Хост работает нормально

## Переключение между шаблонами

Для переключения между LUKS и RAID1:

1. Измените **Partition Table** хоста
2. Измените переменные хоста (добавьте/удалите `crypto_passphrase`)
3. Переведите хост в режим **Build**

## См. также

- [Provisioning шаблоны](../05-provisioning-templates/)
- [LUKS/TPM шифрование](../06-encryption-luks-tpm/)
- [RAID1 конфигурация](../07-raid1-configuration/)

