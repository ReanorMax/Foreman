#!/bin/bash
# Скрипт для разметки, форматирования и монтирования диска данных
# Используется в late_command для автоматического монтирования дисков данных

set -euo pipefail

DISK="${DISK:-/dev/sdb}"
MOUNT_POINT="${MOUNT_POINT:-/home/storage/local}"
LOG_FILE="/var/log/data_disk_mount.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [MOUNT] $*" >> "$LOG_FILE" 2>&1
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [MOUNT] ERROR: $*" >> "$LOG_FILE" 2>&1
}

log "Starting data disk mounting: $DISK -> $MOUNT_POINT"

# Проверка наличия диска
if [ ! -b "$DISK" ]; then
    log_error "Disk $DISK not found"
    exit 1
fi

log "Disk $DISK found"

# Проверка, не смонтирован ли уже диск
if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    log "Mount point $MOUNT_POINT already mounted, skipping"
    exit 0
fi

# Создание точки монтирования
mkdir -p "$MOUNT_POINT"
log "Mount point $MOUNT_POINT created"

# Проверка наличия разделов
if [ -b "${DISK}1" ]; then
    log "Partition ${DISK}1 already exists"
    PARTITION="${DISK}1"
else
    log "Creating partition on $DISK"
    
    # Создание GPT таблицы и раздела
    parted -s "$DISK" mklabel gpt 2>>"$LOG_FILE" || {
        log_error "Failed to create GPT label"
        exit 1
    }
    
    # Создание раздела на весь диск
    parted -s "$DISK" mkpart primary ext4 0% 100% 2>>"$LOG_FILE" || {
        log_error "Failed to create partition"
        exit 1
    }
    
    # Ожидание появления раздела
    sleep 2
    udevadm settle
    
    # Определение номера раздела (может быть sdb1, sdbp1 и т.д.)
    PARTITION=$(lsblk -ln -o NAME "$DISK" | grep -E "^\s*[a-z]+[0-9]+" | head -1)
    if [ -z "$PARTITION" ]; then
        # Если не нашли через lsblk, пробуем стандартное имя
        PARTITION="${DISK}1"
    else
        PARTITION="/dev/$PARTITION"
    fi
    
    # Проверка наличия раздела
    if [ ! -b "$PARTITION" ]; then
        log_error "Partition $PARTITION not found after creation"
        exit 1
    fi
    
    log "Partition $PARTITION created"
fi

# Форматирование раздела
log "Checking if partition is formatted"
if ! blkid "$PARTITION" >/dev/null 2>&1; then
    log "Formatting partition $PARTITION"
    mkfs.ext4 -F "$PARTITION" 2>>"$LOG_FILE" || {
        log_error "Failed to format partition"
        exit 1
    }
    log "Partition formatted successfully"
else
    log "Partition already formatted"
fi

# Получение UUID
UUID=$(blkid -s UUID -o value "$PARTITION" 2>/dev/null || echo "")
if [ -z "$UUID" ]; then
    log_error "Failed to get UUID for partition"
    exit 1
fi

log "Partition UUID: $UUID"

# Добавление в /etc/fstab (если еще не добавлен)
if ! grep -q "UUID=$UUID" /etc/fstab 2>/dev/null; then
    log "Adding partition to /etc/fstab"
    echo "UUID=$UUID $MOUNT_POINT ext4 defaults 0 2" >> /etc/fstab
    log "Partition added to /etc/fstab"
else
    log "Partition already in /etc/fstab"
fi

# Монтирование
log "Mounting partition to $MOUNT_POINT"
mount "$MOUNT_POINT" 2>>"$LOG_FILE" || {
    log_error "Failed to mount partition"
    exit 1
}

log "Partition mounted successfully"

# Установка прав доступа
chmod 755 "$MOUNT_POINT"
log "Permissions set for $MOUNT_POINT"

log "Data disk mounting completed successfully"
exit 0

