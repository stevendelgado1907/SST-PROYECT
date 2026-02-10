<?php
// test_connection.php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>Prueba de Conexión y Datos</h1>";

require_once 'config/Database.php';

try {
    $database = new Database();
    $db = $database->getConnection();

    if ($db) {
        echo "<p style='color:green'>✅ Conexión a Base de Datos EXITOSA.</p>";
    } else {
        echo "<p style='color:red'>❌ Error al conectar (objeto null).</p>";
        exit;
    }

    // Check Brands
    $query = "SELECT count(*) as count FROM tab_marcas";
    $stmt = $db->prepare($query);
    $stmt->execute();
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "<p>Marcas encontradas: <strong>" . $row['count'] . "</strong></p>";

    // Check Categories
    $query = "SELECT count(*) as count FROM tab_categorias";
    $stmt = $db->prepare($query);
    $stmt->execute();
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "<p>Categorías encontradas: <strong>" . $row['count'] . "</strong></p>";

    // Check EPP Count
    $query = "SELECT count(*) as count FROM tab_epp";
    $stmt = $db->prepare($query);
    $stmt->execute();
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "<p>EPPs actuales: <strong>" . $row['count'] . "</strong></p>";

} catch (Exception $e) {
    echo "<p style='color:red'>❌ Excepción: " . $e->getMessage() . "</p>";
}
?>
