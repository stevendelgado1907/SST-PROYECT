<?php
// backend/api/dashboard/stats.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Cache-Control: no-cache, no-store, must-revalidate");

require_once '../../config/Database.php';
require_once '../../api/middleware/AuthMiddleware.php';

AuthMiddleware::validate();

$database = new Database();
$db = $database->getConnection();

try {
    $stats = [];

    // 1. Total Workers (Active)
    // Assuming active workers have null retirement date or future retirement date
    $queryWorkers = "SELECT COUNT(*) as total FROM tab_trabajadores WHERE fecha_retiro_trabajador IS NULL OR fecha_retiro_trabajador > CURRENT_DATE";
    $stmtWorkers = $db->prepare($queryWorkers);
    if ($stmtWorkers->execute()) {
        $stats['totalWorkers'] = $stmtWorkers->fetch(PDO::FETCH_ASSOC)['total'];
    } else {
        $stats['totalWorkers'] = 0;
    }

    // 2. Total EPP in Stock (Sum of all stock)
    // Using COALESCE to return 0 if table is empty
    $queryEpp = "SELECT COALESCE(SUM(stock_actual), 0) as total FROM inventario_epp";
    $stmtEpp = $db->prepare($queryEpp);
    if ($stmtEpp->execute()) {
        $stats['totalEpp'] = $stmtEpp->fetch(PDO::FETCH_ASSOC)['total'];
    } else {
        $stats['totalEpp'] = 0;
    }

    // 3. Total Risks
    $queryRisks = "SELECT COUNT(*) as total FROM tab_riesgos";
    $stmtRisks = $db->prepare($queryRisks);
    if ($stmtRisks->execute()) {
        $stats['totalRisks'] = $stmtRisks->fetch(PDO::FETCH_ASSOC)['total'];
    } else {
        $stats['totalRisks'] = 0;
    }

    // 4. EPP Expiring Soon (Next 30 days) - PostgreSQL syntax
    $queryExpiring = "SELECT COUNT(*) as total FROM tab_epp 
                      WHERE fecha_vencimiento_epp BETWEEN CURRENT_DATE AND (CURRENT_DATE + INTERVAL '30 days') 
                      AND estado_epp = 'DISPONIBLE'";
    
    $stmtExpiring = $db->prepare($queryExpiring);
    if ($stmtExpiring->execute()) {
        $stats['expiringSoon'] = $stmtExpiring->fetch(PDO::FETCH_ASSOC)['total'];
    } else {
        $stats['expiringSoon'] = 0;
    }

    // 5. Inventario bajo stock (stock <= stock_minimo)
    $queryLowStock = "SELECT COUNT(*) as total FROM inventario_epp WHERE stock_actual <= stock_minimo";
    $stmtLowStock = $db->prepare($queryLowStock);
    if ($stmtLowStock->execute()) {
        $stats['lowStock'] = $stmtLowStock->fetch(PDO::FETCH_ASSOC)['total'];
    } else {
        $stats['lowStock'] = 0;
    }

    echo json_encode($stats);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "message" => "Error al obtener estadísticas.",
        "error" => $e->getMessage()
    ]);
}
?>
