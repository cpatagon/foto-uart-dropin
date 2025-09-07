#!/bin/bash
"""
Auto-Update Script para Raspberry Pi
====================================
Actualiza automáticamente el código desde GitHub manteniendo configuraciones locales.

Uso:
    bash scripts/setup/auto_update.sh [--force] [--branch=main]

Características:
- ✅ Preserva configuraciones locales
- ✅ Backup automático antes de actualizar
- ✅ Rollback en caso de error
- ✅ Logging detallado
- ✅ Verificación de integridad
"""

set -euo pipefail  # Modo strict

# Configuración
PROJECT_NAME="foto-uart-dropin"
REPO_URL="https://github.com/cpatagon/foto-uart-dropin.git"
PROJECT_DIR="$HOME/$PROJECT_NAME"
BACKUP_DIR="$HOME/backups/$PROJECT_NAME"
BRANCH="${BRANCH:-main}"
FORCE_UPDATE=false
LOG_FILE="/var/log/foto-uart-update.log"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función de logging
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

info() { log "INFO" "${BLUE}$*${NC}"; }
warn() { log "WARN" "${YELLOW}$*${NC}"; }
error() { log "ERROR" "${RED}$*${NC}"; }
success() { log "SUCCESS" "${GREEN}$*${NC}"; }

# Verificar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_UPDATE=true
            shift
            ;;
        --branch=*)
            BRANCH="${1#*=}"
            shift
            ;;
        -h|--help)
            echo "Uso: $0 [--force] [--branch=main]"
            echo "  --force    Forzar actualización incluso si no hay cambios"
            echo "  --branch   Especificar rama (default: main)"
            exit 0
            ;;
        *)
            error "Argumento desconocido: $1"
            exit 1
            ;;
    esac
done

# Verificar prerrequisitos
check_prerequisites() {
    info "Verificando prerrequisitos..."
    
    # Verificar git
    if ! command -v git &> /dev/null; then
        error "Git no está instalado"
        exit 1
    fi
    
    # Verificar conexión a internet
    if ! ping -c 1 github.com &> /dev/null; then
        error "No hay conexión a internet"
        exit 1
    fi
    
    # Verificar permisos de escritura
    if [[ ! -w "$(dirname "$PROJECT_DIR")" ]]; then
        error "No hay permisos de escritura en $(dirname "$PROJECT_DIR")"
        exit 1
    fi
    
    success "Prerrequisitos OK"
}

# Crear backup de configuraciones
backup_configs() {
    info "Creando backup de configuraciones..."
    
    local backup_timestamp=$(date '+%Y%m%d_%H%M%S')
    local current_backup="$BACKUP_DIR/$backup_timestamp"
    
    mkdir -p "$current_backup"
    
    # Backup de archivos importantes
    local files_to_backup=(
        "config/raspberry_pi/config.json"
        "data/logs"
        ".env"
        "venv"
    )
    
    for file in "${files_to_backup[@]}"; do
        local full_path="$PROJECT_DIR/$file"
        if [[ -e "$full_path" ]]; then
            local backup_path="$current_backup/$file"
            mkdir -p "$(dirname "$backup_path")"
            cp -r "$full_path" "$backup_path"
            info "Backup: $file → $backup_path"
        fi
    done
    
    # Mantener solo los últimos 5 backups
    cd "$BACKUP_DIR"
    ls -t | tail -n +6 | xargs -r rm -rf
    
    echo "$current_backup" > "$BACKUP_DIR/latest"
    success "Backup completado: $current_backup"
}

# Clonar o actualizar repositorio
update_repository() {
    info "Actualizando repositorio..."
    
    if [[ ! -d "$PROJECT_DIR/.git" ]]; then
        info "Clonando repositorio por primera vez..."
        git clone "$REPO_URL" "$PROJECT_DIR"
        cd "$PROJECT_DIR"
        git checkout "$BRANCH"
    else
        cd "$PROJECT_DIR"
        
        # Guardar cambios locales si los hay
        if ! git diff-index --quiet HEAD --; then
            warn "Hay cambios locales no commitados, guardando en stash..."
            git stash push -m "Auto-stash before update $(date)"
        fi
        
        # Fetch y verificar si hay actualizaciones
        git fetch origin
        local local_commit=$(git rev-parse HEAD)
        local remote_commit=$(git rev-parse "origin/$BRANCH")
        
        if [[ "$local_commit" == "$remote_commit" ]] && [[ "$FORCE_UPDATE" == false ]]; then
            info "No hay actualizaciones disponibles"
            return 0
        fi
        
        info "Actualizando desde $local_commit a $remote_commit"
        git reset --hard "origin/$BRANCH"
    fi
    
    success "Repositorio actualizado"
}

# Restaurar configuraciones
restore_configs() {
    info "Restaurando configuraciones..."
    
    local latest_backup_file="$BACKUP_DIR/latest"
    if [[ ! -f "$latest_backup_file" ]]; then
        warn "No hay backup disponible para restaurar"
        return 0
    fi
    
    local latest_backup=$(cat "$latest_backup_file")
    
    # Restaurar archivos de configuración
    local files_to_restore=(
        "config/raspberry_pi/config.json"
        ".env"
    )
    
    for file in "${files_to_restore[@]}"; do
        local backup_path="$latest_backup/$file"
        local target_path="$PROJECT_DIR/$file"
        
        if [[ -f "$backup_path" ]]; then
            mkdir -p "$(dirname "$target_path")"
            cp "$backup_path" "$target_path"
            info "Restaurado: $file"
        fi
    done
    
    # Restaurar virtual environment si existe
    if [[ -d "$latest_backup/venv" ]]; then
        cp -r "$latest_backup/venv" "$PROJECT_DIR/"
        info "Virtual environment restaurado"
    fi
    
    success "Configuraciones restauradas"
}

# Instalar/actualizar dependencias
update_dependencies() {
    info "Actualizando dependencias..."
    
    cd "$PROJECT_DIR"
    
    # Crear virtual environment si no existe
    if [[ ! -d "venv" ]]; then
        info "Creando virtual environment..."
        python3 -m venv venv
    fi
    
    # Activar virtual environment
    source venv/bin/activate
    
    # Actualizar pip
    pip install --upgrade pip
    
    # Instalar dependencias
    if [[ -f "requirements.txt" ]]; then
        pip install -r requirements.txt
    elif [[ -f "requirements/base.txt" ]]; then
        pip install -r requirements/base.txt
    fi
    
    success "Dependencias actualizadas"
}

# Verificar instalación
verify_installation() {
    info "Verificando instalación..."
    
    cd "$PROJECT_DIR"
    source venv/bin/activate
    
    # Verificar que el módulo principal se puede importar
    if python -c "from src.raspberry_pi.foto_uart import FotoUART; print('✅ Import OK')" 2>/dev/null; then
        success "Verificación de importación exitosa"
    else
        error "Error al importar módulo principal"
        return 1
    fi
    
    # Verificar configuración
    if [[ -f "config/raspberry_pi/config.json" ]]; then
        if python -c "import json; json.load(open('config/raspberry_pi/config.json'))" 2>/dev/null; then
            success "Configuración JSON válida"
        else
            error "Configuración JSON inválida"
            return 1
        fi
    else
        warn "No se encontró archivo de configuración"
    fi
    
    success "Instalación verificada"
}

# Reiniciar servicios si es necesario
restart_services() {
    info "Verificando servicios..."
    
    # Si hay un servicio systemd configurado
    if systemctl is-active --quiet foto-uart.service 2>/dev/null; then
        info "Reiniciando servicio foto-uart..."
        sudo systemctl restart foto-uart.service
        sleep 2
        
        if systemctl is-active --quiet foto-uart.service; then
            success "Servicio reiniciado correctamente"
        else
            error "Error al reiniciar servicio"
            return 1
        fi
    else
        info "No hay servicio systemd configurado"
    fi
}

# Rollback en caso de error
rollback() {
    error "Error durante la actualización, ejecutando rollback..."
    
    local latest_backup_file="$BACKUP_DIR/latest"
    if [[ ! -f "$latest_backup_file" ]]; then
        error "No hay backup disponible para rollback"
        return 1
    fi
    
    local latest_backup=$(cat "$latest_backup_file")
    
    # Restaurar desde backup
    if [[ -d "$latest_backup" ]]; then
        info "Restaurando desde backup: $latest_backup"
        
        # Restaurar archivos críticos
        cp -r "$latest_backup"/* "$PROJECT_DIR/" 2>/dev/null || true
        
        success "Rollback completado"
        return 0
    else
        error "Backup no encontrado: $latest_backup"
        return 1
    fi
}

# Función principal
main() {
    info "=== Iniciando Auto-Update de $PROJECT_NAME ==="
    
    # Trap para ejecutar rollback en caso de error
    trap 'rollback' ERR
    
    check_prerequisites
    backup_configs
    update_repository
    restore_configs
    update_dependencies
    verify_installation
    restart_services
    
    success "=== Actualización completada exitosamente ==="
    info "Logs disponibles en: $LOG_FILE"
    
    # Mostrar información de la versión actual
    cd "$PROJECT_DIR"
    local current_commit=$(git rev-parse --short HEAD)
    local current_date=$(git log -1 --format=%cd --date=short)
    info "Versión actual: $current_commit ($current_date)"
}

# Ejecutar función principal
main "$@"
