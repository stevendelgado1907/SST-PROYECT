<?php
// backend/api/middleware/AuthMiddleware.php
require_once __DIR__ . '/../../config/JWT.php';
require_once __DIR__ . '/../../config/Config.php';

class AuthMiddleware {
    public static function validate() {
        // 1. Obtener token: cookie (principal) o header Authorization (fallback)
        $jwt = null;
        if (isset($_COOKIE['auth_token'])) {
            $jwt = $_COOKIE['auth_token'];
        } else {
            $auth = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
            if (preg_match('/Bearer\s+(.+)$/i', $auth, $m)) {
                $jwt = trim($m[1]);
            }
        }
        if (!$jwt) {
            http_response_code(401);
            echo json_encode(["message" => "No autenticado. Token no encontrado."]);
            exit();
        }

        // 2. Configurar secreto (asegurar que coincida con login.php)
        $secret = Config::get('JWT_SECRET') ?? 'fallback_secret_key_change_in_production';
        JWT::setSecret($secret);

        // 3. Decodificar y Validar
        $payload = JWT::decode($jwt);

        if (!$payload) {
            http_response_code(401);
            echo json_encode(["message" => "Token inválido o expirado."]);
            exit();
        }

        // 4. Retornar datos del usuario para que el script los use si es necesario
        return $payload['data'];
    }
}
?>
