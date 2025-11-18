#!/bin/bash
# Скрипт для создания /var логического тома внутри существующего LVM setup
# Используется в late_command для создания /var раздела когда используется choose_recipe select home

set -euo pipefail

LOG_FILE="/var/log/var_creation.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [VAR] $*" >> "$LOG_FILE" 2>&1
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [VAR] ERROR: $*" >> "$LOG_FILE" 2>&1
}

VAR_SIZE="${VAR_SIZE:-40G}"
VG_NAME="debian-vg"
LV_VAR="var"
LV_HOME="home"
MOUNT_POINT="/var"
LOGICAL_SIZE="${VAR_SIZE}"

log "Starting /var LV creation with size: $VAR_SIZE"

# Проверка наличия Volume Group
if ! vgs "$VG_NAME" >/dev/null 2>&1; then
    log_error "Volume group '$VG_NAME' not found"
    exit 1
fi

log "Volume group '$VG_NAME' found"

# Проверка свободного места
VGFREE=$(vgs --noheadings --units g -o vg_free "$VG_NAME" | awk '{print int($1)}')
log "Free space in VG: ${VGFREE}G"

if [ "$VGFREE" -lt 45 ]; then
    log "Not enough free space (${VGFREE}G < 45G). Attempting to resize /home LV"
    
    # Проверка наличия /home LV
    if ! lvs "$VG_NAME/$LV_HOME" >/dev/null 2>&1; then
        log_error "Logical volume '$VG_NAME/$LV_HOME' not found"
        exit 1
    fi
    
    # Получение текущего размера /home
    HOME_SIZE=$(lvs --noheadings --units g -o lv_size "$VG_NAME/$LV_HOME" | awk '{print int($1)}')
    log "Current /home LV size: ${HOME_SIZE}G"
    
    # Расчет нового размера /home (уменьшаем на 45GB)
    NEW_HOME_SIZE=$((HOME_SIZE - 45))
    if [ "$NEW_HOME_SIZE" -lt 10 ]; then
        log_error "Cannot resize /home: new size would be too small (${NEW_HOME_SIZE}G < 10G)"
        exit 1
    fi
    
    log "Resizing /home LV to ${NEW_HOME_SIZE}G"
    
    # Размонтирование /home если смонтирован
    if mountpoint -q "$MOUNT_POINT/../home" 2>/dev/null; then
        log "Unmounting /home"
        umount "$MOUNT_POINT/../home" || umount -f "$MOUNT_POINT/../home" || umount -l "$MOUNT_POINT/../home"
    fi
    
    # Изменение размера LV и файловой системы
    log "Reducing /home LV size"
    lvreduce -L "${NEW_HOME_SIZE}G" -f "/dev/$VG_NAME/$LV_HOME" 2>>"$LOG_FILE" || {
        log_error "Failed to reduce /home LV size"
        exit 1
    }
    
    log "Resizing /home filesystem"
    resize2fs "/dev/$VG_NAME/$LV_HOME" 2>>"$LOG_FILE" || {
        log_error "Failed to resize /home filesystem"
        exit 1
    }
    
    # Повторное монтирование /home
    if mountpoint -q "$MOUNT_POINT/../home" 2>/dev/null; then
        mount "/dev/$VG_NAME/$LV_HOME" "$MOUNT_POINT/../home" 2>>"$LOG_FILE" || {
            log_error "Failed to remount /home"
            exit 1
        }
    fi
    
    log "/home LV resized successfully"
fi

# Создание /var LV
log "Creating /var LV with size: $LOGICAL_SIZE"
lvcreate -L "$LOGICAL_SIZE" -n "$LV_VAR" "$VG_NAME" 2>>"$LOG_FILE" || {
    log_error "Failed to create /var LV"
    exit 1
}

log "/var LV created successfully"

# Форматирование
log "Formatting /var LV"
mkfs.ext4 -F "/dev/$VG_NAME/$LV_VAR" 2>>"$LOG_FILE" || {
    log_error "Failed to format /var LV"
    exit 1
}

log "/var LV formatted successfully"

# Монтирование
log "Mounting /var LV"
mount "/dev/$VG_NAME/$LV_VAR" "$MOUNT_POINT" 2>>"$LOG_FILE" || {
    log_error "Failed to mount /var LV"
    exit 1
}

log "/var LV mounted successfully"

# Копирование существующих данных из /var (если есть)
if [ -d "$MOUNT_POINT.old" ]; then
    log "Copying existing /var data"
    cp -a "$MOUNT_POINT.old"/* "$MOUNT_POINT/" 2>>"$LOG_FILE" || {
        log_error "Failed to copy /var data"
    }
fi

# Добавление в /etc/fstab
log "Adding /var to /etc/fstab"
UUID=$(blkid -s UUID -o value "/dev/$VG_NAME/$LV_VAR" 2>/dev/null || echo "")
if [ -n "$UUID" ]; then
    echo "UUID=$UUID $MOUNT_POINT ext4 defaults 0 2" >> /etc/fstab
    log "/var added to /etc/fstab with UUID: $UUID"
else
    log_error "Failed to get UUID for /var LV"
    exit 1
fi

log "/var LV creation completed successfully"
exit 0

