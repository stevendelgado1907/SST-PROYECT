<?php
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
                id_eps as id, 
                nom_eps as name, 
                direccion_eps as address, 
                tel_eps as phone, 
                correo_eps as email 
              FROM fn_tab_eps_select() 
              ORDER BY nom_eps ASC";
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    $items = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $items[] = $row;
    }
    echo json_encode($items);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => "Error al leer EPS: " . $e->getMessage()]);
}
