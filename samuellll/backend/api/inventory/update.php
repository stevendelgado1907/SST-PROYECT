<?php
// backend/api/inventory/update.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once '../../config/Database.php';
require_once '../../api/middleware/AuthMiddleware.php';

AuthMiddleware::validate();

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->id)) {
    try {
        $query = "UPDATE inventario_epp
                SET
                    stock_actual = :stock,
                    stock_minimo = :min_stock,
                    stock_maximo = :max_stock,
                    punto_reorden = :reorder,
                    ultima_actualizacion = NOW()
                WHERE id_inventario = :id";

        $stmt = $db->prepare($query);

        // Vincular parámetros (Bind)
        $stmt->bindParam(":id", $data->id);
        $stmt->bindParam(":stock", $data->stock);
        $stmt->bindParam(":min_stock", $data->min_stock);
        $stmt->bindParam(":max_stock", $data->max_stock);
        $stmt->bindParam(":reorder", $data->reorder_point);

        if ($stmt->execute()) {
            http_response_code(200);
            echo json_encode(["message" => "Inventario actualizado exitosamente."]);
        } else {
            throw new Exception("Error al actualizar inventario.");
        }
    } catch (Exception $e) {
        http_response_code(503);
        echo json_encode(["message" => "Error: " . $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["message" => "ID requerido."]);
}
?>
