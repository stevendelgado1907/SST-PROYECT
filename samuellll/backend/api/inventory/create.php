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

// Mantener robustez ante JSON inválido
$raw = file_get_contents("php://input");
$data = json_decode($raw);

if (json_last_error() !== JSON_ERROR_NONE || $data === null) {
    http_response_code(400);
    echo json_encode(["message" => "Datos JSON inválidos o vacíos."]);
    exit();
}

if (!empty($data->epp_id)) {
    try {
        // Defaults if not provided
        $stock = (int)(isset($data->stock) ? $data->stock : 0);
        $min_stock = (int)(isset($data->min_stock) ? $data->min_stock : 10);
        $max_stock = (int)(isset($data->max_stock) ? $data->max_stock : 100);
        $reorder = (int)(isset($data->reorder_point) ? $data->reorder_point : 20);
        $eppId = (int)$data->epp_id;

        // Validaciones de dominio antes de tocar la base de datos
        if ($stock < 0) {
            http_response_code(400);
            echo json_encode(["message" => "El stock actual no puede ser negativo."]);
            exit();
        }
        if ($max_stock <= $min_stock) {
            http_response_code(400);
            echo json_encode(["message" => "El stock máximo debe ser mayor que el stock mínimo."]);
            exit();
        }
        if ($reorder < $min_stock || $reorder > $max_stock) {
            http_response_code(400);
            echo json_encode(["message" => "El punto de reorden debe estar entre el stock mínimo y el máximo."]);
            exit();
        }

        // Asegurar existencia y sincronización de la secuencia, igual que en create EPP
        try {
            $db->exec("CREATE SEQUENCE IF NOT EXISTS seq_inventario");
            $db->query("SELECT setval('seq_inventario', GREATEST(COALESCE((SELECT MAX(id_inventario) FROM inventario_epp), 0) + 1, 1), false)");
        } catch (PDOException $seqEx) {
            error_log("Error inicializando secuencia de inventario: " . $seqEx->getMessage());
        }

        // Check if exists
        $checkQ = "SELECT id_inventario FROM inventario_epp WHERE id_epp = :id_epp";
        $stCheck = $db->prepare($checkQ);
        $stCheck->bindParam(":id_epp", $eppId, PDO::PARAM_INT);
        $stCheck->execute();

        if ($stCheck->rowCount() > 0) {
            // Update instead of creating duplicate
            $invId = $stCheck->fetch(PDO::FETCH_ASSOC)['id_inventario'];
            $query = "UPDATE inventario_epp 
                      SET stock_actual = :stock, stock_minimo = :min_stock, 
                          stock_maximo = :max_stock, punto_reorden = :reorder,
                          ultima_actualizacion = NOW()
                      WHERE id_inventario = :inv_id";
            $stmt = $db->prepare($query);
            $stmt->bindParam(":inv_id", $invId, PDO::PARAM_INT);
        } else {
            // Create new usando la misma secuencia que el alta automática de EPP
            $seq = $db->query("SELECT nextval('seq_inventario') AS next_id");
            $nextInvId = $seq->fetch(PDO::FETCH_ASSOC)['next_id'];

            $query = "INSERT INTO inventario_epp (id_inventario, id_epp, stock_actual, stock_minimo, stock_maximo, punto_reorden)
                      VALUES (:inv_id, :id_epp, :stock, :min_stock, :max_stock, :reorder)";
            $stmt = $db->prepare($query);
            $stmt->bindParam(":inv_id", $nextInvId, PDO::PARAM_INT);
            $stmt->bindParam(":id_epp", $eppId, PDO::PARAM_INT);
        }
        
        $stmt->bindParam(":stock", $stock, PDO::PARAM_INT);
        $stmt->bindParam(":min_stock", $min_stock, PDO::PARAM_INT);
        $stmt->bindParam(":max_stock", $max_stock, PDO::PARAM_INT);
        $stmt->bindParam(":reorder", $reorder, PDO::PARAM_INT);
    
        if ($stmt->execute()) {
            http_response_code(201);
            echo json_encode(["message" => "Inventario procesado exitosamente."]);
        } else {
            throw new Exception("No se pudo procesar el inventario.");
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
