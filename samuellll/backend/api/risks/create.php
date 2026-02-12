<?php
// backend/api/risks/create.php
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
    !empty($data->name) &&
    !empty($data->type) &&
    !empty($data->level)
) {
    try {
        error_log("Create Risk called: " . json_encode($data), 3, "debug_log.txt");

        $maxRetries = 3;
        $attempt = 0;
        $success = false;
        $lastError = "";

        do {
            $attempt++;
            try {
                // Determine next ID
                $qMax = "SELECT COALESCE(MAX(id_riesgo), 0) + 1 as next_id FROM tab_riesgos";
                $st = $db->query($qMax);
                $nextId = $st->fetch(PDO::FETCH_ASSOC)['next_id'];
                
                error_log("Attempt $attempt: Next ID: " . $nextId, 3, "debug_log.txt");

                $query = "INSERT INTO tab_riesgos (id_riesgo, nom_riesgo, tipo_riesgo, descripcion_riesgo, nivel_de_riesgo, probabilidad_riesgo, severidad_riesgo, medidas_control)
                          VALUES (:id, :name, :type, :description, :level, :probability, :severity, :measures)";

                $stmt = $db->prepare($query);
                $stmt->bindParam(":id", $nextId);

                // Sanitize (Moved outside loop ideally, but okay here for now or just referencing vars)
                // Note: Bind params are by reference, so we can set them once outside if we want, 
                // but let's just re-bind to be safe and simple in this block structure.
                
                // Validaciones backend coherentes con BD
                // Validar tipo riesgo (valores permitidos según HTML)
                $allowedTypes = ['FÍSICO', 'QUÍMICO', 'BIOLÓGICO', 'ERGONÓMICO', 'PSICOSOCIAL', 'MECÁNICO', 'ELÉCTRICO', 'LOCATIVO', 'INCENDIO'];
                if (!in_array($data->type, $allowedTypes)) {
                    http_response_code(400);
                    echo json_encode(["message" => "Tipo de riesgo inválido."]);
                    exit;
                }

                // Validar probabilidad (valores permitidos según HTML)
                $allowedProbabilities = ['BAJA', 'MEDIA', 'ALTA'];
                $probability = !empty($data->probability) ? htmlspecialchars(strip_tags($data->probability)) : 'BAJA';
                if (!in_array($probability, $allowedProbabilities)) {
                    http_response_code(400);
                    echo json_encode(["message" => "Probabilidad inválida. Debe ser BAJA, MEDIA o ALTA."]);
                    exit;
                }

                // Validar severidad (valores permitidos según HTML)
                $allowedSeverities = ['LEVE', 'MODERADA', 'GRAVE', 'MUY GRAVE'];
                $severity = !empty($data->severity) ? htmlspecialchars(strip_tags($data->severity)) : 'LEVE';
                if (!in_array($severity, $allowedSeverities)) {
                    http_response_code(400);
                    echo json_encode(["message" => "Severidad inválida. Debe ser LEVE, MODERADA, GRAVE o MUY GRAVE."]);
                    exit;
                }

                // Validar longitudes según BD
                if (strlen($data->name) > 100) {
                    http_response_code(400);
                    echo json_encode(["message" => "El nombre del riesgo no puede exceder 100 caracteres."]);
                    exit;
                }
                // BD: medidas_control VARCHAR(255)
                if (!empty($data->measures) && strlen($data->measures) > 255) {
                    http_response_code(400);
                    echo json_encode(["message" => "Las medidas de control no pueden exceder 255 caracteres."]);
                    exit;
                }

                // Sanitize input
                $name = htmlspecialchars(strip_tags($data->name));
                $type = htmlspecialchars(strip_tags($data->type));
                $description = !empty($data->description) ? htmlspecialchars(strip_tags($data->description)) : '';
                
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

                $measures = !empty($data->measures) ? htmlspecialchars(strip_tags($data->measures)) : '';

                $stmt->bindParam(":name", $name);
                $stmt->bindParam(":type", $type);
                $stmt->bindParam(":description", $description);
                $stmt->bindParam(":level", $level);
                $stmt->bindParam(":probability", $probability);
                $stmt->bindParam(":severity", $severity);
                $stmt->bindParam(":measures", $measures);

                if ($stmt->execute()) {
                    $success = true;
                    error_log("Insert success for ID: " . $nextId, 3, "debug_log.txt");
                    http_response_code(201);
                    echo json_encode(["message" => "Riesgo creado exitosamente."]);
                }
            } catch (PDOException $e) {
                // Check for unique violation (PostgreSQL 23505)
                if ($e->getCode() == '23505' && strpos($e->getMessage(), 'tab_riesgos_pkey') !== false) {
                    error_log("Duplicate ID collision for ID: $nextId. Retrying...", 3, "debug_log.txt");
                    if ($attempt >= $maxRetries) {
                        $lastError = "Error de concurrencia: No se pudo generar un ID único después de varios intentos.";
                    }
                    // Continue loop
                    continue; 
                } else {
                    throw $e; // Rethrow other errors
                }
            }
        } while (!$success && $attempt < $maxRetries);

        if (!$success) {
            throw new Exception($lastError ?: "Error al crear riesgo.");
        }

    } catch (Exception $e) {
        error_log("Exception: " . $e->getMessage(), 3, "debug_log.txt");
        http_response_code(503);
        echo json_encode(["message" => "Error: " . $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["message" => "Datos incompletos."]);
}
?>
