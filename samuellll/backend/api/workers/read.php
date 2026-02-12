<?php
// backend/api/workers/read.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../../config/Database.php';
require_once '../../api/middleware/AuthMiddleware.php';

AuthMiddleware::validate();

$database = new Database();
$db = $database->getConnection();

try {
    // Query workers with position, ARL, and EPS
    // Using LEFT JOIN to ensure workers are listed even if they don't have ARL/EPS assigned yet
    // Query using the professional PostgreSQL function with explicit columns
    $query = "SELECT 
                id_trabajador,
                tipo_documento,
                id_cargo,
                nom_trabajador,
                ape_trabajador,
                tel_trabajador,
                correo_trabajador,
                direccion_trabajador,
                rh_trabajador,
                sexo_trabajador,
                fecha_ingreso_trabajador,
                fecha_retiro_trabajador,
                fecha_registro,
                nom_cargo,
                id_arl,
                nom_arl,
                id_eps,
                nom_eps
              FROM fn_tab_trabajadores_select()
              ORDER BY fecha_registro DESC, nom_trabajador ASC";
              
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    $workers = [];
    
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        // Map to format expected by main.js
        $workers[] = [
            "id" => $row['id_trabajador'],
            "doc_type" => $row['tipo_documento'],
            "name" => $row['nom_trabajador'],
            "lastName" => $row['ape_trabajador'],
            "position" => $row['nom_cargo'],
            "position_id" => $row['id_cargo'],
            "startDate" => $row['fecha_ingreso_trabajador'],
            "fecha_retiro_trabajador" => $row['fecha_retiro_trabajador'] ?? null,
            "fecha_registro" => $row['fecha_registro'] ?? null,
            "phone" => $row['tel_trabajador'],
            "email" => $row['correo_trabajador'],
            "address" => $row['direccion_trabajador'] ?? '',
            "rh" => $row['rh_trabajador'] ?? '',
            "sex" => $row['sexo_trabajador'] ?? '',
            "arl" => $row['nom_arl'] ? $row['nom_arl'] : 'Sin Asignar',
            "arl_id" => $row['id_arl'] ?? null,
            "eps" => $row['nom_eps'] ? $row['nom_eps'] : 'Sin Asignar',
            "eps_id" => $row['id_eps'] ?? null
        ];
    }
    
    echo json_encode($workers);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => "Error al obtener trabajadores: " . $e->getMessage()]);
}
?>
