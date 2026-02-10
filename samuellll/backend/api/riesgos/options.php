<?php
// backend/api/riesgos/options.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Origin: *"); // Ajustar para producción

require_once '../../config/Database.php';
require_once '../../config/JWT.php';

// Verificación (Simplificada por ahora, puede ser extraída)
if (!isset($_COOKIE['auth_token'])) {
    http_response_code(401);
    echo json_encode(["message" => "No autorizado"]);
    exit;
}

try {
    $database = new Database();
    $db = $database->getConnection();

    // Obtener Áreas
    $queryAreas = "SELECT id, nombre FROM areas WHERE activo = TRUE ORDER BY nombre";
    $stmtAreas = $db->prepare($queryAreas);
    $stmtAreas->execute();
    $areas = $stmtAreas->fetchAll(PDO::FETCH_ASSOC);

    // Obtener Procesos
    $queryProcess = "SELECT id, area_id, nombre FROM procesos WHERE activo = TRUE ORDER BY nombre";
    $stmtProcess = $db->prepare($queryProcess);
    $stmtProcess->execute();
    $processes = $stmtProcess->fetchAll(PDO::FETCH_ASSOC);

    // Obtener Tipos de Riesgo
    $queryTypes = "SELECT id, nombre, codigo, color FROM tipos_riesgo WHERE activo = TRUE ORDER BY nombre";
    $stmtTypes = $db->prepare($queryTypes);
    $stmtTypes->execute();
    $types = $stmtTypes->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "areas" => $areas,
        "procesos" => $processes,
        "tipos" => $types
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => "Error al obtener opciones", "error" => $e->getMessage()]);
}
?>
