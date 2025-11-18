# LUKS/TPM Encryption Configuration

Настройка полнодискового шифрования с автоматической разблокировкой через TPM2.

## Обзор

- **LUKS2**: Шифрование диска
- **TPM2**: Автоматическая разблокировка при загрузке
- **Clevis**: Интеграция между LUKS и TPM2

## Требования

- TPM2 устройство на сервере
- Пакеты: `clevis`, `clevis-tpm2`, `clevis-initramfs`, `tpm2-tools`

## Настройка в шаблоне

В Template 196 установите переменную хоста:

```
crypto_passphrase = ваш_секретный_пароль
```

## Скрипт: luks_tpm_enroll.sh

Скрипт автоматически регистрирует LUKS разделы в TPM2.

**Расположение:** `configs/scripts/luks_tpm_enroll.sh`

**Выполняется:** Автоматически в `late_command` при установке

## Проверка

```bash
# Проверка TPM
tpm2_getcap properties-fixed

# Проверка Clevis биндингов
clevis luks list -d /dev/sda3

# Проверка initramfs
lsinitramfs /boot/initrd.img-* | grep clevis
```

## См. также

- [Provisioning шаблоны](../05-provisioning-templates/)
- [Troubleshooting](../11-troubleshooting/)

