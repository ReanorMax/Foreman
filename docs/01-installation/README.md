# Установка Foreman с нуля

Пошаговая инструкция по установке Foreman 3.16 на Debian 12.

## Предварительные требования

- Debian 12 (Bookworm) сервер
- Минимум 4 GB RAM
- Минимум 20 GB свободного места на диске
- Доступ к интернету для установки пакетов
- Статический IP-адрес

## Шаг 1: Обновление системы

```bash
apt-get update
apt-get upgrade -y
apt-get install -y ca-certificates curl wget gnupg lsb-release
```

## Шаг 2: Добавление репозитория Foreman

```bash
echo "deb http://deb.theforeman.org/ bookworm 3.16" > /etc/apt/sources.list.d/foreman.list
echo "deb http://deb.theforeman.org/ plugins 3.16" >> /etc/apt/sources.list.d/foreman.list
wget -q https://deb.theforeman.org/pubkey.gpg -O- | apt-key add -
apt-get update
```

## Шаг 3: Установка Foreman Installer

```bash
apt-get install -y foreman-installer
```

## Шаг 4: Базовая установка Foreman

```bash
foreman-installer \
  --enable-foreman \
  --enable-foreman-proxy \
  --enable-puppet \
  --puppet-server \
  --enable-puppet \
  --foreman-proxy-dhcp=true \
  --foreman-proxy-dhcp-interface=enp1s0 \
  --foreman-proxy-dhcp-gateway=192.168.0.1 \
  --foreman-proxy-dhcp-nameservers="192.168.0.6,8.8.8.8" \
  --foreman-proxy-dhcp-range="192.168.0.100 192.168.0.200" \
  --foreman-proxy-dhcp-server=127.0.0.1 \
  --foreman-proxy-tftp=true \
  --foreman-proxy-tftp-servername=192.168.0.209 \
  --enable-foreman-plugin-ansible \
  --enable-foreman-plugin-templates
```

## Шаг 5: Проверка установки

```bash
systemctl status foreman
systemctl status foreman-proxy
systemctl status apache2
systemctl status isc-dhcp-server
systemctl status tftpd-hpa
```

## Шаг 6: Первоначальный доступ

После установки Foreman создаст автоматически пароль для пользователя `admin`. Получить его можно командой:

```bash
foreman-rake permissions:reset
# Или посмотреть в /var/log/foreman-installer/foreman.log
```

Доступ к веб-интерфейсу:
- URL: `https://your-server-ip/` или `https://server.example.com/`
- Пользователь: `admin`
- Пароль: (см. команду выше)

## Шаг 7: Настройка сетевого интерфейса

Убедитесь, что сетевой интерфейс настроен со статическим IP:

```bash
# /etc/network/interfaces
auto enp1s0
iface enp1s0 inet static
    address 192.168.0.209
    netmask 255.255.255.0
    gateway 192.168.0.1
    dns-nameservers 8.8.8.8 1.1.1.1
```

Применить настройки:

```bash
ip route add default via 192.168.0.1 dev enp1s0
systemctl restart networking
```

## Следующие шаги

После установки перейдите к:
- [Базовая настройка](../02-basic-configuration/)
- [Настройка DHCP](../03-dhcp-setup/)
- [Настройка TFTP и HTTPBoot](../04-tftp-httpboot/)

