<?php
// backend/api/risks/delete.php
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

if (!empty($data->id)) {
    try {
        $query = "DELETE FROM tab_riesgos WHERE id_riesgo = :id";
        $stmt = $db->prepare($query);

        $data->id = htmlspecialchars(strip_tags($data->id));
        $stmt->bindParam(":id", $data->id);

        if ($stmt->execute()) {
            if ($stmt->rowCount() > 0) {
                http_response_code(200);
                echo json_encode(["message" => "Riesgo eliminado exitosamente."]);
            } else {
                http_response_code(404);
                echo json_encode(["message" => "Riesgo no encontrado."]);
            }
        } else {
            throw new Exception("No se pudo eliminar el riesgo.");
        }
    } catch (Exception $e) {
        http_response_code(503);
        echo json_encode(["message" => "Error al eliminar riesgo: " . $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["message" => "ID no proporcionado."]);
}
?>
