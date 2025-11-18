# TFTP и HTTPBoot Configuration

Настройка TFTP и HTTPBoot для PXE загрузки.

## TFTP (Trivial File Transfer Protocol)

### Установка

```bash
apt-get install -y tftpd-hpa
```

### Конфигурация

```bash
# /etc/default/tftpd-hpa
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/var/lib/tftpboot"
TFTP_ADDRESS=":69"
TFTP_OPTIONS="--secure"
```

### Расположение файлов

```
/var/lib/tftpboot/
├── autoexec.ipxe          # iPXE скрипт загрузки
├── ipxe.efi               # iPXE для UEFI
├── snponly.efi            # iPXE для Intel I210 NIC
└── undionly.kpxe          # iPXE для Legacy BIOS
```

### Проверка

```bash
systemctl status tftpd-hpa
netstat -ulnp | grep :69
```

## HTTPBoot

### Настройка в Foreman-proxy

HTTPBoot включен в Smart Proxy. См. [Smart Proxy настройки](../09-smart-proxy/).

### Структура файлов

```
/var/lib/foreman/public/httpboot/debian12/
├── vmlinuz                # Ядро Linux (симлинк)
└── initrd.gz              # Initramfs (симлинк)
```

### Создание симлинков

```bash
mkdir -p /var/lib/foreman/public/httpboot/debian12
ln -s ../debian12/vmlinuz /var/lib/foreman/public/httpboot/debian12/vmlinuz
ln -s ../debian12/initrd.gz /var/lib/foreman/public/httpboot/debian12/initrd.gz
```

## iPXE скрипт: autoexec.ipxe

См. полный скрипт в `configs/ipxe/autoexec.ipxe`.

```ipxe
#!ipxe
dhcp
kernel http://10.19.1.209:8000/httpboot/debian12/vmlinuz auto=true priority=critical preseed/url=http://10.19.1.209:8000/unattended/provision?mac=${net0/mac} quiet
initrd http://10.19.1.209:8000/httpboot/debian12/initrd.gz
boot
```

## Проверка работы

```bash
# TFTP
tftp localhost <<EOF
get autoexec.ipxe
quit
EOF

# HTTPBoot
curl -I http://10.19.1.209:8000/httpboot/debian12/vmlinuz
```

## См. также

- [iPXE загрузка](../10-ipxe-boot/)
- [DHCP настройка](../03-dhcp-setup/)

