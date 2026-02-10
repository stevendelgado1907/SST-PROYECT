<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

require_once '../../config/Database.php';
require_once '../../api/middleware/AuthMiddleware.php';

AuthMiddleware::validate();

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (empty($data->id)) {
    http_response_code(400);
    echo json_encode(["message" => "ID requerido."]);
    exit;
}

try {
    $id = (int)$data->id;
    $q = "DELETE FROM tab_ips WHERE id_ips = :id";
    $stmt = $db->prepare($q);
    $stmt->bindParam(":id", $id);
    
    if ($stmt->execute()) {
        echo json_encode(["message" => "IPS eliminada exitosamente."]);
    } else {
        throw new Exception("Error al eliminar.");
    }
} catch (PDOException $e) {
    if ($e->getCode() == 23503) {
        http_response_code(400);
        echo json_encode(["message" => "No se puede eliminar. Existen trabajadores asociados."]);
    } else {
        http_response_code(500);
        echo json_encode(["message" => $e->getMessage()]);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => $e->getMessage()]);
}
