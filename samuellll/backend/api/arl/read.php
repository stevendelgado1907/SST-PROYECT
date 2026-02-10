<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../../config/Database.php';
require_once '../../api/middleware/AuthMiddleware.php';

AuthMiddleware::validate();

$database = new Database();
$db = $database->getConnection();

try {
    $query = "SELECT id_arl as id, nom_arl as name, nit_arl as nit, direccion_arl as address, 
              tel_arl as phone, correo_arl as email FROM tab_arl ORDER BY nom_arl ASC";
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    $items = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $items[] = $row;
    }
    echo json_encode($items);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => "Error al leer ARL: " . $e->getMessage()]);
}
