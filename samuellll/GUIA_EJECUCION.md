# Guía de Ejecución en Servidor 10.5.213.111 (Ubuntu)

Se ha detectado que el servidor remoto corre **Ubuntu** y el proyecto se encuentra en `/var/www/html/protego/`.

## 1. Solución al Error 404 y Errores de Inclusión
1. **Ruta del Proyecto**: El proyecto debe estar en `/var/www/html/protego/`.
2. **Inclusión de Archivos**: He corregido `test_connection.php`. Si otros archivos fallan, asegúrese de que el código use:
   `require_once 'backend/config/Database.php';`
3. **Permisos**:
   ```bash
   sudo chown -R www-data:www-data /var/www/html/protego/
   sudo chmod -R 755 /var/www/html/protego/
   ```

## 2. Inicialización del Administrador
Antes de iniciar sesión, debe asegurarse de que el usuario administrador existe en la base de datos del servidor:
1. Ejecute el script de configuración:
   `http://10.5.213.111/protego/setup_admin.php`
2. Debería ver un mensaje de **¡ÉXITO!**. Esto creará el usuario con el correo y contraseña definidos en su archivo `.env`.

## 3. Inicio de Sesión
Una vez configurado el administrador:
1. Vaya a: `http://10.5.213.111/protego/index.html`
2. Use las siguientes credenciales (por defecto):
   - **Correo**: `admin@sst.com`
   - **Contraseña**: `Admin123`

## 4. Verificación de Entorno (Si algo falla)
Acceda a estas URLs para diagnosticar:
- **Drivers**: `http://10.5.213.111/protego/test_drivers.php`
- **Conexión DB**: `http://10.5.213.111/protego/test_connection.php`
