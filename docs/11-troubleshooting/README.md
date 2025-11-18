# Troubleshooting Guide

Решение типичных проблем при настройке и работе Foreman.

## Проблемы с сетью

### Нет интернета на Foreman сервере

```bash
# Проверка маршрута
ip route
# Добавление маршрута
ip route add default via 192.168.0.1 dev enp1s0
```

### DHCP не выдает IP

1. Проверьте статус сервиса:
   ```bash
   systemctl status isc-dhcp-server
   ```

2. Проверьте синтаксис конфига:
   ```bash
   dhcpd -t -cf /etc/dhcp/dhcpd.conf
   ```

3. Проверьте интерфейс:
   ```bash
   grep INTERFACES /etc/default/isc-dhcp-server
   ```

## Проблемы с установкой

### Диски перепутываются

1. Используйте стабильные `by-id` пути:
   ```
   disk_sys = /dev/disk/by-id/wwn-0xEXAMPLEc500a1234567
   ```

2. Проверьте `partman/early_command` в шаблоне

### Шифрование не работает

1. Проверьте переменную `crypto_passphrase` в параметрах хоста
2. Проверьте доступность скрипта:
   ```bash
   wget http://192.168.0.104:8081/repository/artifacts-local/usr/share/foreman/public/luks_tpm_enroll.sh
   ```
3. Проверьте логи: `/var/log/tpm.log`

### /var раздел не создается

1. Проверьте, что используется LVM (LUKS метод)
2. Проверьте логи: `/var/log/var_creation.log`
3. Проверьте доступность скрипта `create_var_lv.sh`

## Проблемы с iPXE

### iPXE не загружается

1. Проверьте правильный бинарник для NIC:
   - Intel I210 → `snponly.efi`
   - Стандартный → `ipxe.efi`
   - Legacy BIOS → `undionly.kpxe`

2. Проверьте DHCP:
   ```bash
   grep filename /etc/dhcp/dhcpd.hosts
   ```

### iPXE зависает

Используйте `snponly.efi` для Intel I210 NIC.

## Проблемы с Smart Proxy

### Ошибка 404 для logs

1. Проверьте `/etc/foreman-proxy/settings.d/logs.yml`
2. Проверьте `trusted_hosts` в `settings.yml`
3. Перезапустите:
   ```bash
   systemctl restart foreman-proxy
   ```

## Логи

### Важные файлы логов

- Foreman: `/var/log/foreman/production.log`
- Foreman-proxy: `/var/log/foreman-proxy/proxy.log`
- DHCP: `/var/log/syslog` (grep dhcpd)
- Установка (на клиенте):
  - `/var/log/var_creation.log`
  - `/var/log/tpm.log`
  - `/var/log/data_disk_mount.log`

## См. также

- [DHCP настройка](../03-dhcp-setup/)
- [iPXE загрузка](../10-ipxe-boot/)
- [Provisioning шаблоны](../05-provisioning-templates/)

