<?php
// backend/api/epp/delete.php
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

if (!empty($data->id)) {
    try {
        $query = "DELETE FROM tab_epp WHERE id_epp = :id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(":id", $data->id);

        if ($stmt->execute()) {
            http_response_code(200);
            echo json_encode(["message" => "EPP eliminado exitosamente."]);
        } else {
            throw new Exception("Error al eliminar EPP.");
        }
    } catch (PDOException $e) {
        http_response_code(503);
        // Code 23000 or specific driver code for FK violation
        if ($e->getCode() == 23000 || $e->getCode() == 23503) {
            echo json_encode(["message" => "No se puede eliminar: El EPP está asignado o en uso."]);
        } else {
            echo json_encode(["message" => "Error DB: " . $e->getMessage()]);
        }
    }
} else {
    http_response_code(400);
    echo json_encode(["message" => "ID requerido."]);
}
?>
