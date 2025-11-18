#!/bin/bash
# Скрипт для регистрации LUKS разделов в TPM2 через Clevis
# Используется в late_command для автоматической регистрации зашифрованных разделов

set -euo pipefail

LUKS_PASSPHRASE_FILE="${LUKS_PASSPHRASE_FILE:-/tmp/pass.tmp}"
LOG_FILE="/var/log/tpm.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [TPM] $*" >> "$LOG_FILE" 2>&1
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [TPM] ERROR: $*" >> "$LOG_FILE" 2>&1
}

log "Starting TPM enrollment for LUKS partitions"

# Проверка наличия TPM устройства
if [ ! -c /dev/tpm0 ] && [ ! -c /dev/tpmrm0 ]; then
    log_error "TPM device not found"
    exit 1
fi

log "TPM device found"

# Проверка наличия парольной фразы
if [ ! -f "$LUKS_PASSPHRASE_FILE" ]; then
    log_error "LUKS passphrase file not found: $LUKS_PASSPHRASE_FILE"
    exit 1
fi

PASSPHRASE=$(cat "$LUKS_PASSPHRASE_FILE")
if [ -z "$PASSPHRASE" ]; then
    log_error "LUKS passphrase is empty"
    exit 1
fi

log "LUKS passphrase loaded"

# Поиск LUKS разделов
LUKS_DEVICES=$(blkid -t TYPE=crypto_LUKS -o device 2>/dev/null || echo "")
if [ -z "$LUKS_DEVICES" ]; then
    log_error "No LUKS devices found"
    exit 1
fi

log "Found LUKS devices: $LUKS_DEVICES"

# Регистрация каждого LUKS раздела
for LUKS_DEVICE in $LUKS_DEVICES; do
    log "Processing LUKS device: $LUKS_DEVICE"
    
    # Получение имени mapping (например, sda3_crypt)
    MAPPER_NAME=$(basename "$LUKS_DEVICE")_crypt
    
    # Проверка, не зарегистрирован ли уже
    if clevis luks list -d "$LUKS_DEVICE" 2>/dev/null | grep -q tpm2; then
        log "LUKS device $LUKS_DEVICE already enrolled with TPM2, skipping"
        continue
    fi
    
    # Регистрация в TPM2
    log "Enrolling $LUKS_DEVICE in TPM2"
    echo "$PASSPHRASE" | clevis luks bind -d "$LUKS_DEVICE" tpm2 '{}' 2>>"$LOG_FILE" <<< "$PASSPHRASE" || {
        log_error "Failed to enroll $LUKS_DEVICE in TPM2"
        continue
    }
    
    log "Successfully enrolled $LUKS_DEVICE in TPM2"
    
    # Добавление clevis в initramfs
    log "Updating initramfs for $LUKS_DEVICE"
    update-initramfs -u -k all 2>>"$LOG_FILE" || {
        log_error "Failed to update initramfs"
    }
    
    log "Initramfs updated for $LUKS_DEVICE"
done

log "TPM enrollment completed successfully"
exit 0

