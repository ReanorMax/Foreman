# iPXE Boot Configuration

Настройка iPXE для сетевой загрузки.

## Выбор правильного бинарника

| NIC/Система | Бинарник | Расположение |
|-------------|----------|--------------|
| Стандартный UEFI | `ipxe.efi` | `/var/lib/tftpboot/ipxe.efi` |
| Intel I210 | `snponly.efi` | `/var/lib/tftpboot/snponly.efi` |
| Legacy BIOS | `undionly.kpxe` | `/var/lib/tftpboot/undionly.kpxe` |

## Установка бинарников

```bash
apt-get install -y ipxe
cp /usr/share/ipxe/ipxe.efi /var/lib/tftpboot/
cp /usr/share/ipxe/snponly.efi /var/lib/tftpboot/
cp /usr/share/ipxe/undionly.kpxe /var/lib/tftpboot/
```

## Настройка DHCP

В `/etc/dhcp/dhcpd.hosts` укажите правильный бинарник для каждого хоста:

```dhcp
host host1.example.com {
  hardware ethernet aa:bb:cc:dd:ee:ff;
  filename "snponly.efi";  # Для Intel I210
}
```

## Решение проблем

### iPXE зависает

Используйте `snponly.efi` для Intel I210 NIC вместо стандартного `ipxe.efi`.

### NBP download successful, но возврат в BIOS

Проверьте:
1. Secure Boot отключен
2. Правильный бинарник выбран для NIC
3. HTTPBoot включен в BIOS

## См. также

- [DHCP настройка](../03-dhcp-setup/)
- [TFTP и HTTPBoot](../04-tftp-httpboot/)

