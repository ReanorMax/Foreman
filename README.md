# Foreman Configuration Documentation

Полная документация по настройке и конфигурации Foreman для автоматизированной установки Debian 12 с поддержкой LUKS/TPM шифрования, RAID1, и управления DHCP.

## Структура репозитория

```
foreman-docs/
├── README.md                          # Этот файл
├── docs/                              # Документация
│   ├── 01-installation/              # Установка Foreman с нуля
│   ├── 02-basic-configuration/       # Базовая настройка
│   ├── 03-dhcp-setup/                # Настройка DHCP
│   ├── 04-tftp-httpboot/             # Настройка TFTP и HTTPBoot
│   ├── 05-provisioning-templates/    # Provisioning шаблоны
│   ├── 06-encryption-luks-tpm/       # LUKS/TPM шифрование
│   ├── 07-raid1-configuration/       # RAID1 конфигурация
│   ├── 08-host-management/           # Управление хостами
│   ├── 09-smart-proxy/               # Smart Proxy настройки
│   ├── 10-ipxe-boot/                 # iPXE загрузка
│   └── 11-troubleshooting/           # Решение проблем
├── configs/                           # Конфигурационные файлы
│   ├── foreman-proxy/                # Foreman-proxy настройки
│   ├── dhcp/                         # DHCP конфигурация
│   ├── ipxe/                         # iPXE скрипты
│   ├── templates/                    # Provisioning шаблоны
│   └── scripts/                      # Вспомогательные скрипты
└── scripts/                          # Утилиты и скрипты

```

## Быстрый старт

1. **Установка Foreman**: См. [docs/01-installation/](docs/01-installation/)
2. **Базовая настройка**: См. [docs/02-basic-configuration/](docs/02-basic-configuration/)
3. **Настройка DHCP**: См. [docs/03-dhcp-setup/](docs/03-dhcp-setup/)
4. **Provisioning шаблоны**: См. [docs/05-provisioning-templates/](docs/05-provisioning-templates/)

## Основные компоненты

- **Foreman**: Управление хостами и шаблонами установки
- **Smart Proxy**: DHCP, TFTP, HTTPBoot, Templates
- **DHCP Server (ISC)**: Выдача IP-адресов и PXE boot
- **TFTP**: Загрузка iPXE бинарников
- **HTTPBoot**: Загрузка kernel/initrd через HTTP
- **Nexus Repository**: Хранение скриптов установки
- **iPXE**: Загрузчик для сетевой установки

## Особенности конфигурации

### Поддерживаемые сценарии

1. **LUKS/TPM шифрование**: Полнодисковое шифрование с TPM2 автоматической разблокировкой
2. **RAID1**: Программный RAID1 для двух дисков
3. **Гибкое разделение дисков**: Настройка размеров разделов через переменные
4. **Многодисковая конфигурация**: Системный диск + диск данных
5. **Автоматическое монтирование**: Автоматическое монтирование дисков данных

### Технические детали

- **OS**: Debian 12 (Bookworm)
- **Foreman версия**: 3.16.0
- **DHCP**: ISC DHCP Server
- **iPXE**: snponly.efi для Intel I210 NIC
- **RAID контроллер**: Avago MegaRAID MR9361-8i
- **Encryption**: LUKS2 + Clevis + TPM2

## Полезные ссылки

- [Foreman Documentation](https://theforeman.org/documentation.html)
- [Debian Preseed](https://wiki.debian.org/DebianInstaller/Preseed)
- [iPXE Documentation](https://ipxe.org/start)

## Лицензия

Internal documentation for organizational use.
