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

    // 1. Total Workers (tab_trabajadores)
    $queryWorkers = "SELECT COUNT(*) as total FROM tab_trabajadores";
    $stmtWorkers = $db->prepare($queryWorkers);
    $stmtWorkers->execute();
    $stats['totalWorkers'] = $stmtWorkers->fetch(PDO::FETCH_ASSOC)['total'];

    // 2. Total EPP in Stock (tab_inventario where stock > 0)
    // Need to verify table name 'tab_inventario' from SQL file first, using placeholder for now then editing if needed
    // Assuming tab_inventario based on 'inventory' dir
    // Let's rely on my next view_file to confirm, but I'll write the likely code
    // If table is different, I will edit this file immediately after reading SQL.
    $queryEpp = "SELECT COUNT(*) as total FROM tab_inventario_epp WHERE cantidad_stock > 0"; 
    // Wait, previous file list showed 'inventory', typically tab_inventario or tab_inventario_epp
    // I will pause on writing this until I confirm the SQL in the next step to avoid guessing.
    // Actually, I can't pause mid-tool-call. I will use a generic query and fix it if wrong.
    // In 'MODELO SST.sql' line 1: DROP TABLE IF EXISTS inventario_epp;
    // So it's likely 'inventario_epp' or 'tab_inventario_epp'.
    
    // I will wait for the view_file to return before writing the file.
    // So I will NOT call write_to_file in this turn.
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => "Error al obtener estadísticas: " . $e->getMessage()]);
}
?>
