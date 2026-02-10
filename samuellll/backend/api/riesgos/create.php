<?php
// backend/api/riesgos/create.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Origin: *");

require_once '../../config/Database.php';
require_once '../../config/Config.php';
require_once '../../config/JWT.php';

// Comprobación de Autenticación
if (!isset($_COOKIE['auth_token'])) {
    http_response_code(401);
    echo json_encode(["message" => "No autorizado"]);
    exit;
}

$jwt = $_COOKIE['auth_token'];
$secret = Config::get('JWT_SECRET'); // O por defecto
if (!$secret) $secret = 'fallback_secret_key_change_in_production'; // Coincidir con el fallback de verify.php
JWT::setSecret($secret);
$payload = JWT::decode($jwt);

if (!$payload) {
    http_response_code(401);
    echo json_encode(["message" => "Token inválido"]);
    exit;
}

$userId = $payload['data']['id']; // Asumiendo la estructura del payload de verify.php

$data = json_decode(file_get_contents("php://input"));

if (
    !isset($data->area_id) ||
    !isset($data->tipo_riesgo_id) ||
    !isset($data->peligro) ||
    !isset($data->probabilidad) ||
    !isset($data->impacto)
) {
    http_response_code(400);
    echo json_encode(["message" => "Datos incompletos"]);
    exit;
}

try {
    $database = new Database();
    $db = $database->getConnection();

    $query = "INSERT INTO matriz_riesgos (
                area_id, proceso_id, tipo_riesgo_id, peligro, descripcion,
                probabilidad, impacto, frecuencia_exposicion, numero_trabajadores_expuestos,
                controles_actuales, 
                eliminacion, sustitucion, controles_ingenieria, controles_administrativos, equipos_proteccion,
                responsable, fecha_identificacion, fecha_evaluacion, creado_por
              ) VALUES (
                :area_id, :proceso_id, :tipo_riesgo_id, :peligro, :descripcion,
                :probabilidad, :impacto, :frecuencia_exposicion, :numero_trabajadores_expuestos,
                :controles_actuales,
                :eliminacion, :sustitucion, :controles_ingenieria, :controles_administrativos, :equipos_proteccion,
                :responsable, :fecha_identificacion, :fecha_evaluacion, :creado_por
              ) RETURNING id";

    $stmt = $db->prepare($query);

    // Sanear y Vincular (Bind)
    $stmt->bindValue(":area_id", $data->area_id, PDO::PARAM_INT);
    $stmt->bindValue(":proceso_id", isset($data->proceso_id) ? $data->proceso_id : null, PDO::PARAM_INT);
    $stmt->bindValue(":tipo_riesgo_id", $data->tipo_riesgo_id, PDO::PARAM_INT);
    $stmt->bindValue(":peligro", htmlspecialchars(strip_tags($data->peligro)));
    $stmt->bindValue(":descripcion", htmlspecialchars(strip_tags($data->descripcion ?? '')));
    $stmt->bindValue(":probabilidad", $data->probabilidad, PDO::PARAM_INT);
    $stmt->bindValue(":impacto", $data->impacto, PDO::PARAM_INT);
    $stmt->bindValue(":frecuencia_exposicion", $data->frecuencia_exposicion); // Comprobación de Enum manejada por la BD
    $stmt->bindValue(":numero_trabajadores_expuestos", $data->numero_trabajadores_expuestos ?? 1, PDO::PARAM_INT);
    $stmt->bindValue(":controles_actuales", htmlspecialchars(strip_tags($data->controles_actuales ?? '')));
    
    // Medidas de control
    $stmt->bindValue(":eliminacion", htmlspecialchars(strip_tags($data->eliminacion ?? '')));
    $stmt->bindValue(":sustitucion", htmlspecialchars(strip_tags($data->sustitucion ?? '')));
    $stmt->bindValue(":controles_ingenieria", htmlspecialchars(strip_tags($data->controles_ingenieria ?? '')));
    $stmt->bindValue(":controles_administrativos", htmlspecialchars(strip_tags($data->controles_administrativos ?? '')));
    $stmt->bindValue(":equipos_proteccion", htmlspecialchars(strip_tags($data->equipos_proteccion ?? '')));
    
    $stmt->bindValue(":responsable", htmlspecialchars(strip_tags($data->responsable ?? '')));
    $stmt->bindValue(":fecha_identificacion", date('Y-m-d'));
    $stmt->bindValue(":fecha_evaluacion", date('Y-m-d'));
    $stmt->bindValue(":creado_por", $userId, PDO::PARAM_INT);

    if ($stmt->execute()) {
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        $lastId = $row['id'];
        
        // Registrar en historial (Podría ser un disparador, pero hacerlo explícito aquí también está bien si los disparadores fallan)
        // Confiamos en los disparadores (triggers) en el script SQL, pero por ahora confiaremos en los de la BD.
        
        http_response_code(201);
        echo json_encode(["message" => "Riesgo creado exitosamente", "id" => $lastId]);
    } else {
        throw new Exception("Error al ejecutar la inserción");
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => "Error al crear riesgo", "error" => $e->getMessage()]);
}
?>
