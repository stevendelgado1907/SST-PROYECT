<?php
// backend/api/risks/update.php
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
    !empty($data->id) &&
    !empty($data->name) &&
    !empty($data->type) &&
    !empty($data->level)
) {
    try {
        $query = "UPDATE tab_riesgos
                SET
                    nom_riesgo = :name,
                    tipo_riesgo = :type,
                    descripcion_riesgo = :description,
                    nivel_de_riesgo = :level,
                    probabilidad_riesgo = :probability,
                    severidad_riesgo = :severity,
                    medidas_control = :measures
                WHERE id_riesgo = :id";

        $stmt = $db->prepare($query);

        // Validaciones backend coherentes con BD
        $allowedTypes = ['FÍSICO', 'QUÍMICO', 'BIOLÓGICO', 'ERGONÓMICO', 'PSICOSOCIAL', 'MECÁNICO', 'ELÉCTRICO', 'LOCATIVO', 'INCENDIO'];
        if (!in_array($data->type, $allowedTypes)) {
            http_response_code(400);
            echo json_encode(["message" => "Tipo de riesgo inválido."]);
            exit;
        }

        $allowedProbabilities = ['BAJA', 'MEDIA', 'ALTA'];
        $probability = !empty($data->probability) ? htmlspecialchars(strip_tags($data->probability)) : 'BAJA';
        if (!in_array($probability, $allowedProbabilities)) {
            http_response_code(400);
            echo json_encode(["message" => "Probabilidad inválida."]);
            exit;
        }

        $allowedSeverities = ['LEVE', 'MODERADA', 'GRAVE', 'MUY GRAVE'];
        $severity = !empty($data->severity) ? htmlspecialchars(strip_tags($data->severity)) : 'LEVE';
        if (!in_array($severity, $allowedSeverities)) {
            http_response_code(400);
            echo json_encode(["message" => "Severidad inválida."]);
            exit;
        }

        if (strlen($data->name) > 100) {
            http_response_code(400);
            echo json_encode(["message" => "El nombre del riesgo no puede exceder 100 caracteres."]);
            exit;
        }
        if (!empty($data->measures) && strlen($data->measures) > 255) {
            http_response_code(400);
            echo json_encode(["message" => "Las medidas de control no pueden exceder 255 caracteres."]);
            exit;
        }

        // Sanitize
    $data->id = htmlspecialchars(strip_tags($data->id));
    $data->name = htmlspecialchars(strip_tags($data->name));
    $data->type = htmlspecialchars(strip_tags($data->type));
    $data->description = !empty($data->description) ? htmlspecialchars(strip_tags($data->description)) : '';

    // Calculate Level Automatically
    $probVal = 1;
    if ($probability === 'MEDIA') $probVal = 2;
    if ($probability === 'ALTA') $probVal = 3;

    $sevVal = 10;
    if ($severity === 'MODERADA') $sevVal = 20;
    if ($severity === 'GRAVE') $sevVal = 60;
    if ($severity === 'MUY GRAVE') $sevVal = 100;

    $score = $probVal * $sevVal;
    
    $level = 'BAJO';
    if ($score > 20) $level = 'MEDIO';
    if ($score > 50) $level = 'ALTO';
    if ($score > 150) $level = 'MUY ALTO';

    $data->measures = !empty($data->measures) ? htmlspecialchars(strip_tags($data->measures)) : '';

    // Bind
    $stmt->bindParam(":id", $data->id);
    $stmt->bindParam(":name", $data->name);
    $stmt->bindParam(":type", $data->type);
    $stmt->bindParam(":description", $data->description);
    $stmt->bindParam(":level", $level);
    $stmt->bindParam(":probability", $probability);
    $stmt->bindParam(":severity", $severity);
    $stmt->bindParam(":measures", $data->measures);

        if ($stmt->execute()) {
            http_response_code(200);
            echo json_encode(["message" => "Riesgo actualizado exitosamente."]);
        } else {
            throw new Exception("Error al actualizar el riesgo.");
        }
    } catch (Exception $e) {
        http_response_code(503);
        echo json_encode(["message" => "Error al actualizar: " . $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["message" => "Datos incompletos."]);
}
?>
