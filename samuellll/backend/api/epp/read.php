<?php
// backend/api/epp/read.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../../config/Database.php';
require_once '../../api/middleware/AuthMiddleware.php';

try {
    AuthMiddleware::validate();
} catch (Exception $e) {
    http_response_code(401);
    echo json_encode(["message" => "Acceso denegado."]);
    exit();
}

$database = new Database();
$db = $database->getConnection();

try {
    // Select all fields from tab_epp + JOIN brands and categories for names
    $query = "SELECT 
                e.id_epp, 
                e.id_marca, 
                e.id_categoria, 
                e.talla_epp, 
                e.nom_epp, 
                e.tipo_epp, 
                e.referencia_epp, 
                e.fabricante_epp, 
                e.nro_serie_epp, 
                e.descripcion_epp, 
                e.fecha_fabricacion_epp, 
                e.fecha_vencimiento_epp, 
                e.fecha_compra_epp, 
                e.vida_util_meses, 
                e.estado_epp,
                m.nom_marca, 
                c.nom_categoria 
              FROM tab_epp e
              LEFT JOIN tab_marcas m ON e.id_marca = m.id_marca
              LEFT JOIN tab_categorias c ON e.id_categoria = c.id_categoria
              ORDER BY e.id_epp DESC";

    $stmt = $db->prepare($query);
    $stmt->execute();
    
    $items = [];
    
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        // Map DB columns to Frontend properties
        $items[] = [
            "id" => $row['id_epp'],
            "name" => $row['nom_epp'],
            "type" => $row['tipo_epp'],
            "brand_id" => $row['id_marca'],
            "brand_name" => $row['nom_marca'] ?? 'Desconocido',
            "category_id" => $row['id_categoria'],
            "category_name" => $row['nom_categoria'] ?? 'Desconocido',
            "size" => $row['talla_epp'],
            "reference" => $row['referencia_epp'],
            "manufacturer" => $row['fabricante_epp'],
            "serial" => $row['nro_serie_epp'],
            "fab_date" => $row['fecha_fabricacion_epp'],
            "exp_date" => $row['fecha_vencimiento_epp'],
            "buy_date" => $row['fecha_compra_epp'],
            "life_months" => $row['vida_util_meses'],
            "description" => $row['descripcion_epp'],
            "status" => $row['estado_epp']
        ];
    }
    
    echo json_encode($items);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => "Error al leer EPPs: " . $e->getMessage()]);
}
?>
