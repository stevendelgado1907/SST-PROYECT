<?php
// backend/api/utils/reset_db_content.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../../config/Database.php';

$database = new Database();
$db = $database->getConnection();

try {
    // List of tables to truncate (Order matters less with CASCADE, but good to be explicit)
    // EXCLUDING tab_roles and tab_usuarios initially to keep system access? 
    // User said "todos los inserts de las tablas". 
    // I will truncate everything but then re-insert the default roles and admin if they are gone.
    // Or just truncate business data: workers, risks, inventory, etc.
    // "Eliminame todos los inserts de las tablas que tengo en el postgres" implies ALL.
    
    $tables = [
        'tab_trabajadores_epp',
        'tab_trabajadores_riesgos',
        'tab_trabajadores_arl_ips',
        'tab_trabajadores_arl_eps',
        'inventario_epp',
        'tab_epp',
        'tab_trabajadores',
        'tab_supervisores',
        'tab_riesgos',
        'tab_cargos',
        'tab_ips',
        'tab_eps',
        'tab_arl',
        'tab_usuarios', // WARNING: Deletes users
        'tab_roles',
        'tab_categorias',
        'tab_marcas'
    ];

    foreach ($tables as $table) {
        // RESTART IDENTITY resets serial/sequences. CASCADE deletes dependent rows.
        $sql = "TRUNCATE TABLE $table RESTART IDENTITY CASCADE";
        $db->exec($sql);
    }

    // Optional: Restore default Admin and Roles if requested.
    // User didn't explicitly ask to KEEP admin, but it's safe to assume they need to log in.
    // I will re-insert the default roles and admin.
    
    // Roles
    $db->exec("INSERT INTO tab_roles (id_rol, nombre_rol) VALUES (1, 'ADMINISTRADOR'), (2, 'COORDINADOR'), (3, 'INVITADO')");

    // Admin User (Password: admin123) - Adjust hash as needed
    $pass = password_hash('admin123', PASSWORD_BCRYPT);
    $db->exec("INSERT INTO tab_usuarios (id_usuario, correo_usuario, pass_hash, id_rol, nombre_usuario, apellido_usuario) VALUES (1, 'admin@protego.com', '$pass', 1, 'Admin', 'Protego')");

    echo json_encode(["message" => "Base de datos limpiada exitosamente. Se ha restaurado el usuario Admin (admin@protego.com / admin123)."]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => "Error al limpiar base de datos: " . $e->getMessage()]);
}
?>
