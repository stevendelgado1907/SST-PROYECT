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
    // Consultar trabajadores con cargo, ARL y EPS
    // Usando LEFT JOIN para asegurar que los trabajadores se listen incluso si aún no tienen ARL/EPS asignados
    $query = "SELECT 
                t.id_trabajador,
                t.tipo_documento,
                t.nom_trabajador,
                t.ape_trabajador,
                t.fecha_ingreso_trabajador,
                t.tel_trabajador,
                t.correo_trabajador,
                t.direccion_trabajador,
                t.rh_trabajador,
                t.sexo_trabajador,
                t.id_cargo,
                c.nom_cargo,
                a.id_arl,
                a.nom_arl,
                e.id_eps,
                e.nom_eps
              FROM tab_trabajadores t
              JOIN tab_cargos c ON t.id_cargo = c.id_cargo
              LEFT JOIN tab_trabajadores_arl_eps tae ON t.id_trabajador = tae.id_trabajador AND tae.fecha_retiro IS NULL
              LEFT JOIN tab_arl a ON tae.id_arl = a.id_arl
              LEFT JOIN tab_eps e ON tae.id_eps = e.id_eps
              ORDER BY t.nom_trabajador ASC";
              
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    $workers = [];
    
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        // Mapear al formato esperado por main.js
        $workers[] = [
            "id" => $row['id_trabajador'],
            "doc_type" => $row['tipo_documento'],
            "name" => $row['nom_trabajador'],
            "lastName" => $row['ape_trabajador'],
            "position" => $row['nom_cargo'],
            "position_id" => $row['id_cargo'],
            "startDate" => $row['fecha_ingreso_trabajador'],
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
