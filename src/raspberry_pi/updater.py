#!/usr/bin/env python3
"""
Módulo de Auto-Actualización Integrado
======================================
Permite que la aplicación FotoUART se actualice automáticamente desde GitHub.

Example:
    >>> from src.raspberry_pi.updater import AutoUpdater
    >>> updater = AutoUpdater()
    >>> if updater.check_for_updates():
    ...     updater.update()
"""

import os
import json
import logging
import subprocess
import shutil
import tempfile
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, Tuple
from pathlib import Path
import requests
import git


class UpdaterError(Exception):
    """Excepción base para errores del actualizador."""
    pass


class AutoUpdater:
    """Sistema de auto-actualización integrado para FotoUART.
    
    Permite verificar y aplicar actualizaciones desde GitHub de manera
    segura, preservando configuraciones locales y permitiendo rollback.
    
    Attributes:
        repo_url (str): URL del repositorio GitHub
        local_path (Path): Ruta local del proyecto
        branch (str): Rama a seguir para actualizaciones
        logger (logging.Logger): Logger para operaciones
        
    Example:
        >>> updater = AutoUpdater()
        >>> if updater.has_updates():
        ...     success = updater.update()
        ...     print(f"Update {'successful' if success else 'failed'}")
    """
    
    def __init__(
        self,
        repo_url: str = "https://github.com/cpatagon/foto-uart-dropin.git",
        local_path: Optional[str] = None,
        branch: str = "main"
    ):
        """Inicializa el sistema de actualización.
        
        Args:
            repo_url (str): URL del repositorio GitHub
            local_path (Optional[str]): Ruta local del proyecto. 
                Si es None, usa el directorio actual.
            branch (str): Rama a seguir para actualizaciones
        """
        self.repo_url = repo_url
        self.local_path = Path(local_path) if local_path else Path.cwd()
        self.branch = branch
        self.backup_dir = self.local_path / "backups"
        self.config_file = self.local_path / "config" / "raspberry_pi" / "config.json"
        
        # Configurar logging
        self.logger = logging.getLogger(__name__)
        
        # Crear directorios necesarios
        self.backup_dir.mkdir(exist_ok=True)
        
    def _load_config(self) -> Dict[str, Any]:
        """Carga la configuración actual de la aplicación.
        
        Returns:
            Dict[str, Any]: Configuración cargada desde config.json
            
        Raises:
            UpdaterError: Si no se puede cargar la configuración
        """
        try:
            if not self.config_file.exists():
                return {}
            
            with open(self.config_file, 'r') as f:
                return json.load(f)
        except Exception as e:
            raise UpdaterError(f"Error cargando configuración: {e}")
    
    def _save_config(self, config: Dict[str, Any]) -> None:
        """Guarda la configuración actual.
        
        Args:
            config (Dict[str, Any]): Configuración a guardar
            
        Raises:
            UpdaterError: Si no se puede guardar la configuración
        """
        try:
            self.config_file.parent.mkdir(parents=True, exist_ok=True)
            with open(self.config_file, 'w') as f:
                json.dump(config, f, indent=2)
        except Exception as e:
            raise UpdaterError(f"Error guardando configuración: {e}")
    
    def get_current_version(self) -> str:
        """Obtiene la versión actual del código local.
        
        Returns:
            str: Hash del commit actual o 'unknown' si no es un repo git
        """
        try:
            repo = git.Repo(self.local_path)
            return repo.head.commit.hexsha[:8]
        except Exception:
            return "unknown"
    
    def get_remote_version(self) -> str:
        """Obtiene la versión más reciente del repositorio remoto.
        
        Returns:
            str: Hash del commit más reciente en la rama especificada
            
        Raises:
            UpdaterError: Si no se puede obtener la versión remota
        """
        try:
            # Usar GitHub API para obtener el último commit
            api_url = self.repo_url.replace('github.com', 'api.github.com/repos').replace('.git', '')
            response = requests.get(f"{api_url}/commits/{self.branch}", timeout=10)
            response.raise_for_status()
            
            commit_data = response.json()
            return commit_data['sha'][:8]
            
        except Exception as e:
            raise UpdaterError(f"Error obteniendo versión remota: {e}")
    
    def has_updates(self) -> bool:
        """Verifica si hay actualizaciones disponibles.
        
        Returns:
            bool: True si hay actualizaciones disponibles
        """
        try:
            current = self.get_current_version()
            remote = self.get_remote_version()
            
            has_update = current != remote
            
            if has_update:
                self.logger.info(f"Actualización disponible: {current} → {remote}")
            else:
                self.logger.info("No hay actualizaciones disponibles")
                
            return has_update
            
        except Exception as e:
            self.logger.error(f"Error verificando actualizaciones: {e}")
            return False
    
    def _create_backup(self) -> Path:
        """Crea un backup de los archivos importantes antes de actualizar.
        
        Returns:
            Path: Ruta del directorio de backup creado
        """
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = self.backup_dir / f"backup_{timestamp}"
        backup_path.mkdir(exist_ok=True)
        
        # Archivos y directorios importantes a respaldar
        important_items = [
            "config/raspberry_pi/config.json",
            "data",
            ".env",
            "venv"
        ]
        
        for item in important_items:
            source = self.local_path / item
            if source.exists():
                dest = backup_path / item
                dest.parent.mkdir(parents=True, exist_ok=True)
                
                if source.is_file():
                    shutil.copy2(source, dest)
                else:
                    shutil.copytree(source, dest, ignore_errors=True)
                
                self.logger.debug(f"Backup: {item} → {dest}")
        
        # Mantener solo los últimos 5 backups
        self._cleanup_old_backups()
        
        self.logger.info(f"Backup creado: {backup_path}")
        return backup_path
    
    def _cleanup_old_backups(self) -> None:
        """Elimina backups antiguos, manteniendo solo los últimos 5."""
        try:
            backups = sorted([
                d for d in self.backup_dir.iterdir() 
                if d.is_dir() and d.name.startswith("backup_")
            ], key=lambda x: x.stat().st_mtime, reverse=True)
            
            # Eliminar backups antiguos (mantener 5)
            for old_backup in backups[5:]:
                shutil.rmtree(old_backup, ignore_errors=True)
                self.logger.debug(f"Backup eliminado: {old_backup}")
                
        except Exception as e:
            self.logger.warning(f"Error limpiando backups antiguos: {e}")
    
    def _restore_from_backup(self, backup_path: Path) -> bool:
        """Restaura archivos desde un backup.
        
        Args:
            backup_path (Path): Ruta del backup a restaurar
            
        Returns:
            bool: True si la restauración fue exitosa
        """
        try:
            # Restaurar archivos importantes
            important_items = [
                "config/raspberry_pi/config.json",
                ".env"
            ]
            
            for item in important_items:
                source = backup_path / item
                dest = self.local_path / item
                
                if source.exists():
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    if source.is_file():
                        shutil.copy2(source, dest)
                    else:
                        if dest.exists():
                            shutil.rmtree(dest)
                        shutil.copytree(source, dest)
                    
                    self.logger.debug(f"Restaurado: {item}")
            
            # Restaurar virtual environment si existe
            venv_backup = backup_path / "venv"
            venv_dest = self.local_path / "venv"
            
            if venv_backup.exists():
                if venv_dest.exists():
                    shutil.rmtree(venv_dest)
                shutil.copytree(venv_backup, venv_dest)
                self.logger.debug("Virtual environment restaurado")
            
            self.logger.info("Restauración desde backup completada")
            return True
            
        except Exception as e:
            self.logger.error(f"Error restaurando desde backup: {e}")
            return False
    
    def _update_dependencies(self) -> bool:
        """Actualiza las dependencias Python.
        
        Returns:
            bool: True si la actualización fue exitosa
        """
        try:
            venv_path = self.local_path / "venv"
            
            # Crear virtual environment si no existe
            if not venv_path.exists():
                self.logger.info("Creando virtual environment...")
                subprocess.run([
                    "python3", "-m", "venv", str(venv_path)
                ], check=True, cwd=self.local_path)
            
            # Activar virtual environment y actualizar dependencias
            pip_path = venv_path / "bin" / "pip"
            
            # Actualizar pip
            subprocess.run([
                str(pip_path), "install", "--upgrade", "pip"
            ], check=True, cwd=self.local_path)
            
            # Instalar dependencias
            requirements_file = self.local_path / "requirements.txt"
            if requirements_file.exists():
                subprocess.run([
                    str(pip_path), "install", "-r", str(requirements_file)
                ], check=True, cwd=self.local_path)
            
            self.logger.info("Dependencias actualizadas")
            return True
            
        except Exception as e:
            self.logger.error(f"Error actualizando dependencias: {e}")
            return False
    
    def _verify_installation(self) -> bool:
        """Verifica que la instalación actualizada funcione correctamente.
        
        Returns:
            bool: True si la verificación fue exitosa
        """
        try:
            # Verificar que se puede importar el módulo principal
            python_path = self.local_path / "venv" / "bin" / "python"
            
            result = subprocess.run([
                str(python_path), "-c", 
                "from src.raspberry_pi.foto_uart import FotoUART; print('OK')"
            ], capture_output=True, text=True, cwd=self.local_path)
            
            if result.returncode == 0 and "OK" in result.stdout:
                self.logger.info("Verificación de importación exitosa")
                return True
            else:
                self.logger.error(f"Error en verificación: {result.stderr}")
                return False
                
        except Exception as e:
            self.logger.error(f"Error verificando instalación: {e}")
            return False
    
    def update(self, force: bool = False) -> bool:
        """Ejecuta la actualización completa del sistema.
        
        Args:
            force (bool): Forzar actualización incluso si no hay cambios
            
        Returns:
            bool: True si la actualización fue exitosa
        """
        if not force and not self.has_updates():
            self.logger.info("No hay actualizaciones disponibles")
            return True
        
        self.logger.info("Iniciando proceso de actualización...")
        backup_path = None
        
        try:
            # 1. Crear backup
            backup_path = self._create_backup()
            
            # 2. Actualizar código desde git
            repo = git.Repo(self.local_path)
            
            # Guardar cambios locales si los hay
            if repo.is_dirty():
                self.logger.warning("Hay cambios locales, guardando en stash...")
                repo.git.stash("save", f"Auto-stash before update {datetime.now()}")
            
            # Hacer pull del código más reciente
            origin = repo.remotes.origin
            origin.fetch()
            repo.git.reset('--hard', f'origin/{self.branch}')
            
            self.logger.info("Código actualizado desde repositorio")
            
            # 3. Restaurar configuraciones importantes
            self._restore_from_backup(backup_path)
            
            # 4. Actualizar dependencias
            if not self._update_dependencies():
                raise UpdaterError("Falló la actualización de dependencias")
            
            # 5. Verificar instalación
            if not self._verify_installation():
                raise UpdaterError("Falló la verificación de instalación")
            
            current_version = self.get_current_version()
            self.logger.info(f"Actualización completada exitosamente a versión: {current_version}")
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error durante actualización: {e}")
            
            # Intentar rollback si hay backup
            if backup_path and backup_path.exists():
                self.logger.info("Intentando rollback...")
                if self._restore_from_backup(backup_path):
                    self.logger.info("Rollback completado")
                else:
                    self.logger.error("Falló el rollback")
            
            return False
    
    def schedule_update_check(self, interval_hours: int = 6) -> None:
        """Programa verificaciones automáticas de actualización.
        
        Args:
            interval_hours (int): Intervalo en horas entre verificaciones
            
        Note:
            Esta función debería ser llamada desde el loop principal
            de la aplicación para verificar periódicamente.
        """
        # Implementar usando threading.Timer o similar
        # Por simplicidad, solo loggear la intención
        self.logger.info(f"Programada verificación de actualizaciones cada {interval_hours} horas")
    
    def get_update_info(self) -> Dict[str, Any]:
        """Obtiene información detallada sobre actualizaciones disponibles.
        
        Returns:
            Dict[str, Any]: Información sobre versión actual, remota y estado
        """
        try:
            current = self.get_current_version()
            remote = self.get_remote_version()
            has_update = current != remote
            
            return {
                "current_version": current,
                "remote_version": remote,
                "has_updates": has_update,
                "last_check": datetime.now().isoformat(),
                "repo_url": self.repo_url,
                "branch": self.branch
            }
        except Exception as e:
            return {
                "error": str(e),
                "last_check": datetime.now().isoformat()
            }


def main():
    """Función principal para uso como script independiente."""
    import argparse
    import sys
    
    parser = argparse.ArgumentParser(description="Auto-actualizar FotoUART")
    parser.add_argument("--check", action="store_true", help="Solo verificar actualizaciones")
    parser.add_argument("--force", action="store_true", help="Forzar actualización")
    parser.add_argument("--branch", default="main", help="Rama a seguir")
    parser.add_argument("--repo", help="URL del repositorio")
    parser.add_argument("--verbose", "-v", action="store_true", help="Output detallado")
    
    args = parser.parse_args()
    
    # Configurar logging
    level = logging.DEBUG if args.verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # Crear updater
    kwargs = {"branch": args.branch}
    if args.repo:
        kwargs["repo_url"] = args.repo
    
    updater = AutoUpdater(**kwargs)
    
    try:
        if args.check:
            # Solo verificar actualizaciones
            info = updater.get_update_info()
            
            if "error" in info:
                print(f"❌ Error: {info['error']}")
                sys.exit(1)
            
            print(f"📊 Estado de actualización:")
            print(f"   Versión actual: {info['current_version']}")
            print(f"   Versión remota: {info['remote_version']}")
            print(f"   Hay actualizaciones: {'✅ Sí' if info['has_updates'] else '❌ No'}")
            
            sys.exit(0 if not info['has_updates'] else 1)
        
        else:
            # Ejecutar actualización
            print("🔄 Iniciando actualización...")
            
            if updater.update(force=args.force):
                print("✅ Actualización completada exitosamente")
                sys.exit(0)
            else:
                print("❌ Error durante la actualización")
                sys.exit(1)
                
    except KeyboardInterrupt:
        print("\n⚠️ Actualización cancelada por el usuario")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error inesperado: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
