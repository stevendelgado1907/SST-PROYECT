<?php
// backend/api/categories/read.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../../config/Database.php';
require_once '../../api/middleware/AuthMiddleware.php';

AuthMiddleware::validate();

$database = new Database();
$db = $database->getConnection();

try {
    $query = "SELECT id_categoria, nom_categoria FROM tab_categorias ORDER BY nom_categoria ASC";
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    $items = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $items[] = [
            "id" => $row['id_categoria'],
            "name" => $row['nom_categoria']
        ];
    }
    echo json_encode($items);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => "Error al leer categorías: " . $e->getMessage()]);
}
?>
