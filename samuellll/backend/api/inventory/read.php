<?php
// backend/api/inventory/read.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../../config/Database.php';
require_once '../../api/middleware/AuthMiddleware.php';

AuthMiddleware::validate();

$database = new Database();
$db = $database->getConnection();

try {
    $query = "SELECT 
                i.*, 
                e.nom_epp, 
                e.referencia_epp, 
                c.nom_categoria, 
                m.nom_marca 
              FROM inventario_epp i
              JOIN tab_epp e ON i.id_epp = e.id_epp
              LEFT JOIN tab_marcas m ON e.id_marca = m.id_marca
              LEFT JOIN tab_categorias c ON e.id_categoria = c.id_categoria
              ORDER BY i.id_inventario DESC";

    $stmt = $db->prepare($query);
    $stmt->execute();
    
    $items = [];
    
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        // Determinar el estado basado en el stock
        $status = 'DISPONIBLE';
        if ($row['stock_actual'] == 0) $status = 'AGOTADO';
        elseif ($row['stock_actual'] <= $row['stock_minimo']) $status = 'BAJO_STOCK';

        $items[] = [
            "id" => $row['id_inventario'],
            "epp_id" => $row['id_epp'],
            "name" => $row['nom_epp'],
            "reference" => $row['referencia_epp'],
            "category" => $row['nom_categoria'],
            "brand" => $row['nom_marca'],
            "stock" => $row['stock_actual'],
            "minStock" => $row['stock_minimo'],
            "maxStock" => $row['stock_maximo'],
            "reorder" => $row['punto_reorden'],
            "lastUpdate" => $row['ultima_actualizacion'],
            "status" => $status
        ];
    }
    
    echo json_encode($items);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => "Error al leer inventario: " . $e->getMessage()]);
}
?>
