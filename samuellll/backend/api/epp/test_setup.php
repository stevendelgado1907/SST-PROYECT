<?php
// Diagnóstico: verificar que fn_insertar_epp y secuencias existan
header("Content-Type: application/json; charset=UTF-8");
require_once '../../config/Database.php';

$db = (new Database())->getConnection();
$ok = [];
$err = [];

try {
    $r = $db->query("SELECT 1 FROM pg_proc WHERE proname = 'fn_insertar_epp'")->fetch();
    $ok['funcion'] = $r ? true : false;
    if (!$r) $err[] = 'fn_insertar_epp no existe. Ejecute: database/functions/Función Insertar EPP.sql';
} catch (Exception $e) { $ok['funcion'] = false; $err[] = $e->getMessage(); }

try {
    $db->query("SELECT 1 FROM seq_epp");
    $ok['seq_epp'] = true;
} catch (Exception $e) { $ok['seq_epp'] = false; $err[] = 'seq_epp no existe'; }

try {
    $db->query("SELECT 1 FROM seq_inventario");
    $ok['seq_inventario'] = true;
} catch (Exception $e) { $ok['seq_inventario'] = false; $err[] = 'seq_inventario no existe'; }

try {
    $r = $db->query("SELECT COUNT(*) as c FROM tab_marcas")->fetch();
    $ok['marcas'] = (int)$r['c'];
} catch (Exception $e) { $ok['marcas'] = 'error'; }

try {
    $r = $db->query("SELECT COUNT(*) as c FROM tab_categorias")->fetch();
    $ok['categorias'] = (int)$r['c'];
} catch (Exception $e) { $ok['categorias'] = 'error'; }

echo json_encode([
    'conexion' => 'ok',
    'checks' => $ok,
    'errores' => $err,
    'listo' => ($ok['funcion'] ?? false) && ($ok['seq_epp'] ?? false) && ($ok['seq_inventario'] ?? false)
], JSON_PRETTY_PRINT);
