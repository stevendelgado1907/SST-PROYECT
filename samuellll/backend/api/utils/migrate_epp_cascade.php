<?php
// backend/api/utils/migrate_epp_cascade.php
require_once '../../config/Database.php';
require_once '../middleware/AuthMiddleware.php';

header("Content-Type: text/plain");

try {
    AuthMiddleware::validate();
    
    $database = new Database();
    $db = $database->getConnection();

    echo "Iniciando migración de integridad referencial...\n";

    // 1. Drop existing FKs and add CASCADE for inventario_epp
    echo "Actualizando inventario_epp...\n";
    $db->exec("ALTER TABLE inventario_epp DROP CONSTRAINT IF EXISTS inventario_epp_id_epp_fkey");
    $db->exec("ALTER TABLE inventario_epp ADD CONSTRAINT inventario_epp_id_epp_fkey 
               FOREIGN KEY (id_epp) REFERENCES tab_epp(id_epp) ON DELETE CASCADE");

    // 2. Drop existing FKs and add CASCADE for tab_trabajadores_epp
    echo "Actualizando tab_trabajadores_epp...\n";
    $db->exec("ALTER TABLE tab_trabajadores_epp DROP CONSTRAINT IF EXISTS tab_trabajadores_epp_id_epp_fkey");
    $db->exec("ALTER TABLE tab_trabajadores_epp ADD CONSTRAINT tab_trabajadores_epp_id_epp_fkey 
               FOREIGN KEY (id_epp) REFERENCES tab_epp(id_epp) ON DELETE CASCADE");

    echo "✅ Migración completada exitosamente.\n";

} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
}
?>
