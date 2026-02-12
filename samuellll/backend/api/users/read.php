<?php
// backend/api/users/read.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../../config/Database.php';
require_once '../../api/middleware/AuthMiddleware.php';

AuthMiddleware::validate();

$database = new Database();
$db = $database->getConnection();

try {
    // Query using the professional PostgreSQL function with explicit columns
    $query = "SELECT 
                id_usuario, 
                correo_usuario, 
                id_rol, 
                estado_usuario, 
                nombre_usuario, 
                apellido_usuario, 
                nombre_rol, 
                ultimo_acceso 
              FROM fn_tab_usuarios_select() 
              ORDER BY id_usuario DESC";
              
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    $users = [];
    
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        // Map to format expected by main.js
        $users[] = [
            "id" => $row['id_usuario'],
            "name" => $row['nombre_usuario'], // First name
            "lastName" => $row['apellido_usuario'],
            "fullName" => $row['nombre_usuario'] . ' ' . $row['apellido_usuario'], // For display
            "email" => $row['correo_usuario'],
            "role" => $row['nombre_rol'],
            "role_id" => $row['id_rol'], // For edit select
            "status" => $row['estado_usuario'],
            "lastAccess" => $row['ultimo_acceso']
        ];
    }
    
    echo json_encode($users);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => "Error al obtener usuarios: " . $e->getMessage()]);
}
?>
