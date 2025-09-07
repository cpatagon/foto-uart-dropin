# Guía de Contribución

¡Gracias por tu interés en contribuir al proyecto FotoUART Drop-in System!

## Proceso de Desarrollo

1. Fork del repositorio
2. Crear rama de feature: `git checkout -b feature/nueva-caracteristica`
3. Hacer cambios y commitear: `git commit -m "feat: descripción"`
4. Ejecutar tests: `pytest`
5. Push: `git push origin feature/nueva-caracteristica`
6. Crear Pull Request

## Estándares de Código

- Usar Black para formateo: `black src/ tests/`
- Seguir PEP 8
- Documentar con Google Style docstrings
- Tests para nuevas características
- Type hints donde sea apropiado

## Commits

Usar Conventional Commits:
- `feat:` nuevas características
- `fix:` corrección de bugs
- `docs:` documentación
- `test:` tests
- `refactor:` refactoring
