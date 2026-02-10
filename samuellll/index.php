<?php
// index.php - Punto de entrada

// Comprobar si index.html existe e incluirlo
if (file_exists('index.html')) {
    include 'index.html';
} else {
    // Alternativa si falta index.html
    header("Location: pages/login.html");
    exit();
}
?>
