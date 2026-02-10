# Proyecto Protego - Gestión SST

Este proyecto es un Sistema de Gestión de Seguridad y Salud en el Trabajo enfocado en la trazabilidad de EPP, gestión de trabajadores y análisis de riesgos mediante una matriz 5x5.

## 📌 Consigna de Desarrollo
Para asegurar la calidad y escalabilidad del proyecto, todo desarrollo debe seguir estas prioridades:
1. **Mantener la lógica de programación aplicada**: Uso de PHP/PDO para backend, JWT para autenticación y Vanilla JavaScript para el frontend.
2. **Respetar la estructura**: Organización clara entre `assets/`, `backend/`, `database/`, `pages/` y `tools/`.
3. **Buena documentación**: El código debe estar comentado y los procesos explicados para facilitar el entendimiento del sistema.
4. **Coherencia y Congruencia**: Cada cambio debe ser integral, asegurando que no existan piezas sueltas o redundantes (como el antiguo sistema de riesgos).

## 📂 Estructura del Proyecto
- `assets/`: Archivos estáticos (CSS, JS, Imágenes).
- `backend/`: Lógica del lado del servidor (API, Config, Middleware).
- `database/`: Scripts SQL de instalación y mantenimiento.
- `pages/`: Vistas HTML (Login y subpáginas).
- `tools/`: Herramientas de diagnóstico y configuración.
- `.env`: Configuración de entorno local (Base de datos, JWT).

## 🚀 Tecnologías
- **Frontend**: HTML5, CSS3 (Custom), JavaScript (ES6+).
- **Backend**: PHP 7.4+ / 8.x.
- **Base de Datos**: PostgreSQL.
- **Seguridad**: Autenticación vía JWT y contraseñas hasheadas (BCRYPT).
