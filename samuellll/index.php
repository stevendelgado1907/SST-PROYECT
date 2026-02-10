<?php
// index.php - Entry point

// Check if index.html exists and include it
if (file_exists('index.html')) {
    include 'index.html';
} else {
    // Fallback if index.html is missing
    header("Location: pages/login.html");
    exit();
}
?>
