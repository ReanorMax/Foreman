# Настройка DHCP для Foreman

Подробная инструкция по настройке ISC DHCP Server для работы с Foreman и PXE boot.

## Обзор

DHCP сервер используется для:
- Выдачи IP-адресов клиентам
- Направления клиентов на PXE boot сервер
- Предоставления имени загрузочного файла (iPXE, grub и т.д.)

## Конфигурационные файлы

### Основной файл: `/etc/dhcp/dhcpd.conf`

Основной файл конфигурации DHCP. См. полный конфиг в `configs/dhcp/dhcpd.conf`.

#### Ключевые параметры:

```dhcp
omapi-port 7911;              # Порт для OMAPI (Foreman использует для управления)
default-lease-time 43200;     # Время аренды по умолчанию (12 часов)
max-lease-time 86400;         # Максимальное время аренды (24 часа)
next-server 192.168.0.209;      # IP адрес TFTP/HTTPBoot сервера
```

#### Подсеть:

```dhcp
subnet 192.168.0.0 netmask 255.255.255.0 {
  option subnet-mask 255.255.255.0;
  option routers 192.168.0.1;
  option domain-name-servers 192.168.0.6, 8.8.8.8;
  
  next-server 192.168.0.209;
  # iPXE для UEFI (x64)
  if option architecture = 00:07 {
    filename "ipxe.efi";
  } else {
    filename "undionly.kpxe";  # Legacy BIOS
  }
}
```

#### Поддержка HTTP Boot:

```dhcp
# Требуется для UEFI HTTP boot
if substring(option vendor-class-identifier, 0, 10) = "HTTPClient" {
  option vendor-class-identifier "HTTPClient";
}
```

### Статические хосты: `/etc/dhcp/dhcpd.hosts`

Файл для статических резерваций IP-адресов. См. `configs/dhcp/dhcpd.hosts`.

#### Пример конфигурации:

```dhcp
# static DHCP hosts

host host1.example.com {
  hardware ethernet aa:bb:cc:dd:ee:ff;
  fixed-address 192.168.0.250;
  option host-name "host1.example.com";
  next-server 192.168.0.209;
  filename "snponly.efi";  # Для Intel I210 NIC
}

host host2.example.com {
  hardware ethernet 11:22:33:44:55:66;
  fixed-address 192.168.0.251;
  option host-name "host2.example.com";
  next-server 192.168.0.209;
  filename "ipxe.efi";
}
```

**Важно:** Используйте `snponly.efi` для Intel I210 NIC, так как стандартный `ipxe.efi` может не работать.

## Настройка в Foreman

### Шаг 1: Создание подсети

1. Перейдите в **Инфраструктура → Подсети → Создать подсеть**
2. Заполните параметры:
   - **Имя**: `Internal Network`
   - **Сеть**: `192.168.0.0/24`
   - **Шлюз**: `192.168.0.1`
   - **DNS серверы**: `192.168.0.6, 8.8.8.8`
   - **Smart Proxy**: Выберите ваш Smart Proxy с DHCP

### Шаг 2: Привязка DHCP Proxy

1. Перейдите в **Инфраструктура → Смарт Прокси**
2. Выберите ваш Smart Proxy
3. Убедитесь, что **DHCP** функция активна
4. В настройках DHCP убедитесь, что:
   - **Server**: `127.0.0.1`
   - **Config**: `/etc/dhcp/dhcpd.conf`
   - **Leases**: `/var/lib/dhcp/dhcpd.leases`

### Шаг 3: Настройка хоста в Foreman

1. Перейдите в **Узлы → Создать узел**
2. Заполните параметры:
   - **Имя**: `host1.example.com.local`
   - **MAC адрес**: `aa:bb:cc:dd:ee:ff`
   - **IPv4 адрес**: `192.168.0.250`
   - **Подсеть**: `Internal Network`
   - **Smart Proxy**: Выберите ваш Smart Proxy

3. При переводе хоста в режим **Build**, Foreman автоматически создаст резервацию в DHCP через OMAPI

## Добавление статических хостов вручную

Если нужно добавить хост вручную (минуя Foreman):

1. Добавьте запись в `/etc/dhcp/dhcpd.hosts`:

```dhcp
host new-host {
  hardware ethernet aa:bb:cc:dd:ee:ff;
  fixed-address 192.168.0.252;
  option host-name "new-host";
  next-server 192.168.0.209;
  filename "ipxe.efi";
}
```

2. Перезагрузите DHCP сервер:

```bash
systemctl restart isc-dhcp-server
systemctl status isc-dhcp-server
```

## Выбор правильного iPXE бинарника

| NIC/Система | Бинарник | Примечание |
|-------------|----------|------------|
| Стандартный UEFI | `ipxe.efi` | Универсальный |
| Intel I210 | `snponly.efi` | Использует UEFI SNP драйвер |
| Legacy BIOS | `undionly.kpxe` | Для старых систем |

### Где находятся бинарники:

```bash
/var/lib/tftpboot/ipxe.efi
/var/lib/tftpboot/snponly.efi
/var/lib/tftpboot/undionly.kpxe
```

Скопировать из системных пакетов:

```bash
cp /usr/share/ipxe/ipxe.efi /var/lib/tftpboot/
cp /usr/share/ipxe/snponly.efi /var/lib/tftpboot/
cp /usr/share/ipxe/undionly.kpxe /var/lib/tftpboot/
```

## Проверка работы

### Проверка статуса DHCP:

```bash
systemctl status isc-dhcp-server
```

### Просмотр логов:

```bash
tail -f /var/log/syslog | grep dhcpd
```

### Просмотр активных аренд:

```bash
cat /var/lib/dhcp/dhcpd.leases | grep -A 10 "lease 10.19.1"
```

### Тестирование OMAPI:

```bash
# Проверка подключения Foreman к DHCP через OMAPI
netstat -tlnp | grep 7911
```

## Решение проблем

### DHCP не запускается

```bash
# Проверка синтаксиса конфигурации
dhcpd -t -cf /etc/dhcp/dhcpd.conf

# Проверка ошибок в логах
journalctl -u isc-dhcp-server -n 50
```

### Клиент не получает IP

1. Убедитесь, что DHCP сервер слушает правильный интерфейс:
   ```bash
   grep -i "INTERFACES" /etc/default/isc-dhcp-server
   # Должно быть: INTERFACESv4="enp1s0"
   ```

2. Проверьте, что порт 67 не занят:
   ```bash
   netstat -ulnp | grep :67
   ```

### Foreman не может управлять DHCP

1. Убедитесь, что OMAPI порт открыт:
   ```bash
   netstat -tlnp | grep 7911
   ```

2. Проверьте настройки Smart Proxy:
   - URL должен быть доступен: `http://192.168.0.209:8000`
   - DHCP функция должна быть активна

## См. также

- [Настройка TFTP и HTTPBoot](../04-tftp-httpboot/)
- [iPXE загрузка](../10-ipxe-boot/)
- [Управление хостами](../08-host-management/)

