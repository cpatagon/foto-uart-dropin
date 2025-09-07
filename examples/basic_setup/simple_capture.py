#!/usr/bin/env python3
"""
Ejemplo básico de captura de imagen
"""
from src.raspberry_pi.foto_uart import FotoUART

def main():
    """Ejemplo de uso básico."""
    with FotoUART() as foto:
        timestamp, data = foto.capture_image(800, 6)
        print(f"Imagen capturada: {timestamp}, {len(data)} bytes")

if __name__ == "__main__":
    main()
