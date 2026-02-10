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

    // 1. Trabajadores Totales (Activos)
    // Asumiendo que los trabajadores activos tienen fecha de retiro nula o una fecha de retiro futura
    $queryWorkers = "SELECT COUNT(*) as total FROM tab_trabajadores WHERE fecha_retiro_trabajador IS NULL OR fecha_retiro_trabajador > CURRENT_DATE";
    $stmtWorkers = $db->prepare($queryWorkers);
    if ($stmtWorkers->execute()) {
        $stats['totalWorkers'] = $stmtWorkers->fetch(PDO::FETCH_ASSOC)['total'];
    } else {
        $stats['totalWorkers'] = 0;
    }

    // 2. Total de EPP en Stock (Suma de todo el stock)
    // Usando COALESCE para devolver 0 si la tabla está vacía
    $queryEpp = "SELECT COALESCE(SUM(stock_actual), 0) as total FROM inventario_epp";
    $stmtEpp = $db->prepare($queryEpp);
    if ($stmtEpp->execute()) {
        $stats['totalEpp'] = $stmtEpp->fetch(PDO::FETCH_ASSOC)['total'];
    } else {
        $stats['totalEpp'] = 0;
    }

    // 3. Riesgos Totales (de la nueva Matriz)
    $queryRisks = "SELECT COUNT(*) as total FROM matriz_riesgos";
    $stmtRisks = $db->prepare($queryRisks);
    if ($stmtRisks->execute()) {
        $stats['totalRisks'] = $stmtRisks->fetch(PDO::FETCH_ASSOC)['total'];
    } else {
        $stats['totalRisks'] = 0;
    }

    // 4. EPP por Vencer Pronto (Próximos 30 días)
    // Buscando fechas de vencimiento en tab_epp
    $queryExpiring = "SELECT COUNT(*) as total FROM tab_epp WHERE fecha_vencimiento_epp BETWEEN CURRENT_DATE AND (CURRENT_DATE + INTERVAL '30 day') AND estado_epp = 'DISPONIBLE'";
    // Nota: Postgres usa INTERVAL '30 day', MySQL usa INTERVAL 30 DAY. 
    // El código anterior sugiere que esto es probablemente MySQL/Genérico.
    // DSN de 'Database.php' muestra 'pgsql', por lo que la sintaxis válida de Postgres es: CURRENT_DATE + INTERVAL '30 day'
    // Revisemos de nuevo Database.php. Mostraba pgsql.
    // Espera, el DSN decía "pgsql:host=...". Así que ES PostgreSQL.
    // Sintaxis de Postgres: WHERE fecha_vencimiento_epp BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 day'
    
    $stmtExpiring = $db->prepare($queryExpiring);
    if ($stmtExpiring->execute()) {
        $stats['expiringSoon'] = $stmtExpiring->fetch(PDO::FETCH_ASSOC)['total'];
    } else {
        $stats['expiringSoon'] = 0;
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
