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
    // Query aligned with MODELO SST.sql and main.js expectations
    $query = "SELECT 
                u.id_usuario, 
                u.nombre_usuario, 
                u.apellido_usuario, 
                u.correo_usuario, 
                u.estado_usuario,
                u.ultimo_acceso,
                u.id_rol,
                r.nombre_rol 
              FROM tab_usuarios u
              JOIN tab_roles r ON u.id_rol = r.id_rol
              ORDER BY u.id_usuario DESC";
              
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
