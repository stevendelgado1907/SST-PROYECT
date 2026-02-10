<?php
// Crear secuencias seq_epp y seq_inventario (requeridas por fn_insertar_epp)
header("Content-Type: application/json; charset=UTF-8");

require_once '../../config/Database.php';

$db = (new Database())->getConnection();
$results = [];

try {
    $db->exec("CREATE SEQUENCE IF NOT EXISTS seq_epp");
    $results['seq_epp_created'] = true;
} catch (PDOException $e) {
    $results['seq_epp_error'] = $e->getMessage();
}

try {
    $db->exec("CREATE SEQUENCE IF NOT EXISTS seq_inventario");
    $results['seq_inventario_created'] = true;
} catch (PDOException $e) {
    $results['seq_inventario_error'] = $e->getMessage();
}

try {
    $db->query("SELECT setval('seq_epp', GREATEST(COALESCE((SELECT MAX(id_epp) FROM tab_epp), 0) + 1, 1))");
    $results['seq_epp_sync'] = true;
} catch (PDOException $e) {
    $results['seq_epp_sync_error'] = $e->getMessage();
}

try {
    $db->query("SELECT setval('seq_inventario', GREATEST(COALESCE((SELECT MAX(id_inventario) FROM inventario_epp), 0) + 1, 1))");
    $results['seq_inventario_sync'] = true;
} catch (PDOException $e) {
    $results['seq_inventario_sync_error'] = $e->getMessage();
}

$results['listo'] = ($results['seq_epp_created'] ?? false) && ($results['seq_inventario_created'] ?? false);
echo json_encode($results, JSON_PRETTY_PRINT);
