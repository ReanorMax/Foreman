# Smart Proxy Configuration

Настройка Foreman Smart Proxy для управления DHCP, TFTP, HTTPBoot и Templates.

## Конфигурационные файлы

### Основной файл: `/etc/foreman-proxy/settings.yml`

См. полный конфиг в `configs/foreman-proxy/settings.yml`.

**Ключевые параметры:**

```yaml
:trusted_hosts:
  - foreman.local
  - 127.0.0.1
  - 10.19.1.209
  - localhost

:foreman_url: https://foreman.local
:bind_host: '*'
:http_port: 8000
:https_port: 8443
:log_level: DEBUG
```

### DHCP модуль: `/etc/foreman-proxy/settings.d/dhcp.yml`

См. полный конфиг в `configs/foreman-proxy/dhcp.yml`.

```yaml
:enabled: https
:use_provider: dhcp_isc
:server: 127.0.0.1
:ping_free_ip: true
```

### Logs модуль: `/etc/foreman-proxy/settings.d/logs.yml`

См. полный конфиг в `configs/foreman-proxy/logs.yml`.

```yaml
:enabled: true
:log_files:
  :foreman-proxy: /var/log/foreman-proxy/proxy.log
  :foreman: /var/log/foreman/production.log
```

### Templates модуль: `/etc/foreman-proxy/settings.d/templates.yml`

См. полный конфиг в `configs/foreman-proxy/templates.yml`.

```yaml
:enabled: http
:template_url: http://10.19.1.209:8000
```

### HTTPBoot модуль: `/etc/foreman-proxy/settings.d/httpboot.yml`

См. полный конфиг в `configs/foreman-proxy/httpboot.yml`.

```yaml
:enabled: true
:root_dir: /var/lib/tftpboot
```

## Проверка работы

```bash
systemctl status foreman-proxy
curl http://127.0.0.1:8000/logs
```

## См. также

- [DHCP настройка](../03-dhcp-setup/)
- [TFTP и HTTPBoot](../04-tftp-httpboot/)

