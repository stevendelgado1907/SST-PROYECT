<?php
// tests/test_login_endpoint.php
// Script para probar "las validaciones de login en PHP" sin usar el navegador

// URL del endpoint de login (AJUSTA SI TU PUERTO NO ES 80)
$url = 'http://localhost/samuellll/backend/api/auth/login.php';

// Datos de prueba (Asegúrate de que este usuario exista en tu DB)
$data = [
    'email' => 'admin@sst.com',
    'password' => 'Admin123'
];

echo "--- Probando Login en Backend ---\n";
echo "URL: $url\n";
echo "Enviando datos: " . json_encode($data) . "\n\n";

// Inicializar CURL
$ch = curl_init($url);

// Configurar opciones de CURL
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));

// Ejecutar petición
$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);

if ($response === false) {
    echo "Error CURL: " . curl_error($ch) . "\n";
} else {
    echo "Código HTTP: $http_code\n";
    echo "Respuesta del Servidor:\n";
    echo "------------------------\n";
    echo $response . "\n";
    echo "------------------------\n";
    
    $json = json_decode($response, true);
    if ($json) {
        if (isset($json['status']) && $json['status'] == 'success') {
            echo "[ÉXITO] El login validó correctamente al usuario.\n";
            echo "Token recibido: " . substr($json['token'], 0, 10) . "...\n";
        } else {
            echo "[FALLO] El backend rechazó el login. Mensaje: " . ($json['message'] ?? 'Desconocido') . "\n";
        }
    } else {
        echo "[ERROR] La respuesta no es JSON válido.\n";
    }
}

curl_close($ch);
echo "\n--- Fin del Test ---\n";
?>
