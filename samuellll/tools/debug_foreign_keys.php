<?php
// debug_foreign_keys.php
require_once 'config/Database.php';

$database = new Database();
$db = $database->getConnection();

echo "--- CHECKING FOREIGN KEYS ---\n";

try {
    // Comprobar Marcas
    $query = "SELECT count(*) as count FROM tab_marcas";
    $stmt = $db->prepare($query);
    $stmt->execute();
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "Brands (tab_marcas) count: " . $row['count'] . "\n";
    
    // Comprobar Categorías
    $query = "SELECT count(*) as count FROM tab_categorias";
    $stmt = $db->prepare($query);
    $stmt->execute();
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "Categories (tab_categorias) count: " . $row['count'] . "\n";

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
echo "--- END ---\n";
?>
