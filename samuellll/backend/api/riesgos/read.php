<?php
// backend/api/riesgos/read.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Origin: *");

require_once '../../config/Database.php';
require_once '../../config/JWT.php';

// Auth Check (Optional: Allow read-only access? Let's restrict for consistency)
if (!isset($_COOKIE['auth_token'])) {
    http_response_code(401);
    echo json_encode(["message" => "No autorizado"]);
    exit;
}

try {
    $database = new Database();
    $db = $database->getConnection();

    $area_id = isset($_GET['area_id']) ? $_GET['area_id'] : null;
    $tipo_id = isset($_GET['tipo_id']) ? $_GET['tipo_id'] : null;
    $nivel = isset($_GET['nivel']) ? $_GET['nivel'] : null; // BAJO, MEDIO, ALTO, EXTREMO
    $estado = isset($_GET['estado']) ? $_GET['estado'] : null;

    $query = "SELECT 
                mr.id,
                mr.peligro,
                a.nombre as area_nombre,
                p.nombre as proceso_nombre,
                tr.nombre as tipo_nombre,
                tr.color as tipo_color,
                mr.probabilidad,
                mr.impacto,
                mr.nivel_riesgo,
                mr.categoria_riesgo,
                mr.estado,
                mr.fecha_identificacion
              FROM matriz_riesgos mr
              JOIN areas a ON mr.area_id = a.id
              LEFT JOIN procesos p ON mr.proceso_id = p.id
              JOIN tipos_riesgo tr ON mr.tipo_riesgo_id = tr.id
              WHERE mr.activo = TRUE";

    if ($area_id) $query .= " AND mr.area_id = :area_id";
    if ($tipo_id) $query .= " AND mr.tipo_riesgo_id = :tipo_id";
    if ($nivel) $query .= " AND mr.categoria_riesgo = :nivel";
    if ($estado) $query .= " AND mr.estado = :estado";

    $query .= " ORDER BY mr.nivel_riesgo DESC, mr.fecha_creacion DESC";

    $stmt = $db->prepare($query);

    if ($area_id) $stmt->bindValue(":area_id", $area_id);
    if ($tipo_id) $stmt->bindValue(":tipo_id", $tipo_id);
    if ($nivel) $stmt->bindValue(":nivel", $nivel);
    if ($estado) $stmt->bindValue(":estado", $estado);

    $stmt->execute();
    $riesgos = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode($riesgos);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => "Error al leer riesgos", "error" => $e->getMessage()]);
}
?>
