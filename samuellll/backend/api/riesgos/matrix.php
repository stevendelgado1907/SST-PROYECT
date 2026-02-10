<?php
// backend/api/riesgos/matrix.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Origin: *"); // Ajustar para producción
require_once '../../config/Database.php';
require_once '../../config/JWT.php';

if (!isset($_COOKIE['auth_token'])) {
    http_response_code(401);
    echo json_encode(["message" => "No autorizado"]);
    exit;
}

try {
    $database = new Database();
    $db = $database->getConnection();

    // Agrupar conteos por Probabilidad e Impacto
    $query = "SELECT 
                probabilidad,
                impacto,
                COUNT(*) as cantidad,
                categoria_riesgo
              FROM matriz_riesgos
              WHERE activo = TRUE
              GROUP BY probabilidad, impacto, categoria_riesgo";

    $stmt = $db->prepare($query);
    $stmt->execute();
    $matrixData = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // También obtener totales
    $queryStats = "SELECT 
                    COUNT(*) as total,
                    SUM(CASE WHEN categoria_riesgo = 'EXTREMO' THEN 1 ELSE 0 END) as extremos,
                    SUM(CASE WHEN categoria_riesgo = 'ALTO' THEN 1 ELSE 0 END) as altos,
                    SUM(CASE WHEN categoria_riesgo = 'MEDIO' THEN 1 ELSE 0 END) as medios,
                    SUM(CASE WHEN categoria_riesgo = 'BAJO' THEN 1 ELSE 0 END) as bajos,
                    AVG(nivel_riesgo) as riesgo_promedio
                   FROM matriz_riesgos WHERE activo = TRUE";
    
    $stmtStats = $db->prepare($queryStats);
    $stmtStats->execute();
    $stats = $stmtStats->fetch(PDO::FETCH_ASSOC);

    echo json_encode([
        "matrix" => $matrixData,
        "stats" => $stats
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => "Error al obtener datos de la matriz", "error" => $e->getMessage()]);
}
?>
