<?php
// backend/api/epp/update.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

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

$data = json_decode(file_get_contents("php://input"));

// Validation
$requiredFields = [
    'id', 'name', 'type', 'brand_id', 'category_id', 'size', 'reference', 
    'manufacturer', 'serial', 'fab_date', 'exp_date', 'buy_date', 
    'life_months', 'description'
];

$missing = [];
foreach ($requiredFields as $field) {
    if (empty($data->$field)) {
        $missing[] = $field;
    }
}

if (!empty($missing)) {
    http_response_code(400);
    echo json_encode(["message" => "Datos incompletos.", "missing" => $missing]);
    exit();
}

try {
    $query = "UPDATE tab_epp
            SET
                id_marca = :brand_id,
                id_categoria = :category_id,
                talla_epp = :size,
                nom_epp = :name,
                tipo_epp = :type,
                referencia_epp = :reference,
                fabricante_epp = :manufacturer,
                nro_serie_epp = :serial,
                descripcion_epp = :description,
                fecha_fabricacion_epp = :fab_date,
                fecha_vencimiento_epp = :exp_date,
                fecha_compra_epp = :buy_date,
                vida_util_meses = :life
            WHERE id_epp = :id";

    $stmt = $db->prepare($query);

    function clean($val) {
        return htmlspecialchars(strip_tags($val));
    }

    $stmt->bindValue(":id", clean($data->id));
    $stmt->bindValue(":brand_id", clean($data->brand_id));
    $stmt->bindValue(":category_id", clean($data->category_id));
    $stmt->bindValue(":size", clean($data->size));
    $stmt->bindValue(":name", clean($data->name));
    $stmt->bindValue(":type", clean($data->type));
    $stmt->bindValue(":reference", clean($data->reference));
    $stmt->bindValue(":manufacturer", clean($data->manufacturer));
    $stmt->bindValue(":serial", clean($data->serial));
    $stmt->bindValue(":description", clean($data->description));
    $stmt->bindValue(":fab_date", clean($data->fab_date));
    $stmt->bindValue(":exp_date", clean($data->exp_date));
    $stmt->bindValue(":buy_date", clean($data->buy_date));
    $stmt->bindValue(":life", clean($data->life_months));

    if ($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["message" => "EPP actualizado exitosamente."]);
    } else {
        throw new Exception("Error al actualizar EPP.");
    }
} catch (PDOException $e) {
    http_response_code(500);
    if ($e->getCode() == 23000) {
        echo json_encode(["message" => "Error: El número de serie ya está en uso."]);
    } else {
        echo json_encode(["message" => "Error DB: " . $e->getMessage()]);
    }
} catch (Exception $e) {
    http_response_code(503);
    echo json_encode(["message" => "Error: " . $e->getMessage()]);
}
?>
