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
                id_cargo as id, 
                nom_cargo as name,
                descripcion_cargo as description,
                nivel_riesgo_cargo as risk_level,
                salario_base as salary,
                departamento as department
              FROM fn_tab_cargos_select() 
              ORDER BY name ASC";
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    $items = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $items[] = $row;
    }
    echo json_encode($items);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => "Error al leer cargos: " . $e->getMessage()]);
}
