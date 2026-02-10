<?php
// backend/api/inventory/create.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once '../../config/Database.php';
require_once '../../api/middleware/AuthMiddleware.php';

AuthMiddleware::validate();

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (
    !empty($data->epp_id)
) {
    try {
        // Defaults if not provided
        $stock = (int)(isset($data->stock) ? $data->stock : 0);
        $min_stock = (int)(isset($data->min_stock) ? $data->min_stock : 10);
        $max_stock = (int)(isset($data->max_stock) ? $data->max_stock : 100);
        $reorder = (int)(isset($data->reorder_point) ? $data->reorder_point : 20);

        $qMax = "SELECT COALESCE(MAX(id_inventario), 0) + 1 as next_id FROM inventario_epp";
        $st = $db->query($qMax);
        $nextInvId = $st->fetch(PDO::FETCH_ASSOC)['next_id'];

        $query = "INSERT INTO inventario_epp (id_inventario, id_epp, stock_actual, stock_minimo, stock_maximo, punto_reorden)
                  VALUES (:inv_id, :id_epp, :stock, :min_stock, :max_stock, :reorder)";
        
        $stmt = $db->prepare($query);
        $stmt->bindParam(":inv_id", $nextInvId);
    
        // Sanitize and bind
        $eppId = (int)htmlspecialchars(strip_tags($data->epp_id));
        $stmt->bindParam(":id_epp", $eppId);
        $stmt->bindParam(":stock", $stock);
        $stmt->bindParam(":min_stock", $min_stock);
        $stmt->bindParam(":max_stock", $max_stock);
        $stmt->bindParam(":reorder", $reorder);
    
        if ($stmt->execute()) {
            http_response_code(201);
            echo json_encode(["message" => "Item de inventario creado exitosamente."]);
        } else {
            throw new Exception("No se pudo crear el item de inventario.");
        }
    } catch (PDOException $e) {
        if ($e->getCode() == 23000) { // Duplicate entry
             http_response_code(409);
             echo json_encode(["message" => "Este EPP ya existe en el inventario."]);
        } else {
            http_response_code(503);
            echo json_encode(["message" => "Error de base de datos: " . $e->getMessage()]);
        }
    } catch (Exception $e) {
        http_response_code(503);
        echo json_encode(["message" => $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["message" => "ID de EPP requerido."]);
}
?>
