<?php
// backend/api/auth/verify.php
header("Content-Type: application/json; charset=UTF-8");

require_once '../../config/Config.php';
require_once '../../config/JWT.php';

if (isset($_COOKIE['auth_token'])) {
    $jwt = $_COOKIE['auth_token'];

    $secret = Config::get('JWT_SECRET') ?? 'fallback_secret_key_change_in_production';
    JWT::setSecret($secret);

    $payload = JWT::decode($jwt);

    if ($payload) {
        // Token valid
        echo json_encode([
            "status" => "valid",
            "user" => $payload['data']
        ]);
        http_response_code(200);
    } else {
        // Token invalid or tamperred
        http_response_code(401);
        echo json_encode(["status" => "invalid", "message" => "Token inválido"]);
    }
} else {
    // No cookie found
    http_response_code(401);
    echo json_encode(["status" => "invalid", "message" => "No hay sesión activa"]);
}
?>
