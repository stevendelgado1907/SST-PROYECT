<?php
// backend/api/brands/read.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../../config/Database.php';
require_once '../../api/middleware/AuthMiddleware.php';

AuthMiddleware::validate();

$database = new Database();
$db = $database->getConnection();

try {
    $query = "SELECT id_marca, nom_marca FROM tab_marcas ORDER BY nom_marca ASC";
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    $items = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $items[] = [
            "id" => $row['id_marca'],
            "name" => $row['nom_marca']
        ];
    }
    echo json_encode($items);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => "Error al leer marcas: " . $e->getMessage()]);
}
?>
