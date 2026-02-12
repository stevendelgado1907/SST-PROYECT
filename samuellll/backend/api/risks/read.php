<?php
// backend/api/risks/read.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Cache-Control: no-cache, no-store, must-revalidate");
header("Pragma: no-cache");
header("Expires: 0");

require_once '../../config/Database.php';
require_once '../../api/middleware/AuthMiddleware.php';

AuthMiddleware::validate();

$database = new Database();
$db = $database->getConnection();

try {
    error_log("Read Risks called", 3, "debug_log.txt");
    // Query using the professional PostgreSQL function with explicit columns
    $query = "SELECT 
                id_riesgo as id,
                nom_riesgo as name,
                tipo_riesgo as type,
                descripcion_riesgo as description,
                nivel_de_riesgo as level,
                probabilidad_riesgo as probability,
                severidad_riesgo as severity,
                medidas_control as measures
              FROM fn_tab_riesgos_select()
              ORDER BY id ASC";
              
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    $items = [];
    $items = [];
    $items = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        // Calculate Risk Score & Percentage
        // Normalize to uppercase and trim to handle manual DB inserts
        $prob = strtoupper(trim($row['probability']));
        $sev = strtoupper(trim($row['severity']));

        $probVal = 0;
        switch($prob) {
            case 'BAJA': $probVal = 1; break;
            case 'MEDIA': $probVal = 2; break;
            case 'ALTA': $probVal = 3; break;
        }

        $sevVal = 0;
        switch($sev) {
            case 'LEVE': $sevVal = 10; break;
            case 'MODERADA': $sevVal = 20; break;
            case 'GRAVE': $sevVal = 60; break;
            case 'MUY GRAVE': $sevVal = 100; break;
        }

        $score = $probVal * $sevVal;
        $maxScore = 300; // 3 * 100
        $percentage = ($score / $maxScore) * 100;

        // Normalize Risk Level
        $calcLevel = $row['level'];
        if ($score <= 20) $calcLevel = 'BAJO';
        elseif ($score <= 50) $calcLevel = 'MEDIO';
        elseif ($score <= 150) $calcLevel = 'ALTO';
        else $calcLevel = 'MUY ALTO';

        $row['score'] = $score;
        $row['percentage'] = round($percentage, 0);
        $row['calculated_level'] = $calcLevel; 
        
        $items[] = $row;
    }
    error_log("Read Risks found: " . count($items), 3, "debug_log.txt");
    echo json_encode($items);

} catch (Exception $e) {
    error_log("Read Risks Error: " . $e->getMessage(), 3, "debug_log.txt");
    http_response_code(500);
    echo json_encode(["message" => "Error al leer riesgos: " . $e->getMessage()]);
}
?>
