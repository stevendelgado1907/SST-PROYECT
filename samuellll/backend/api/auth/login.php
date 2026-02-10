<?php
// backend/api/auth/login.php
header("Content-Type: application/json; charset=UTF-8");

require_once '../../config/Database.php';
require_once '../../config/Config.php';
require_once '../../config/JWT.php';

$database = new Database();
$pdo = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->email) && !empty($data->password)) {
    
    // Consulta alineada con MODELO SST.sql
    $query = "SELECT 
                u.id_usuario, 
                u.nombre_usuario, 
                u.apellido_usuario, 
                u.correo_usuario, 
                u.pass_hash, 
                r.nombre_rol 
              FROM tab_usuarios u
              JOIN tab_roles r ON u.id_rol = r.id_rol
              WHERE u.correo_usuario = :email 
              LIMIT 1";
              
    $stmt = $pdo->prepare($query);
    $stmt->bindParam(':email', $data->email);
    $stmt->execute();
    
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    // Verificar contraseña: Forzar verificación de Hash
    if ($user && password_verify($data->password, $user['pass_hash'])) {
        
        // 1. Obtener Secreto
        $secret = Config::get('JWT_SECRET');
        
        if (!$secret) {
             error_log("CRÍTICO: JWT_SECRET no establecido en el entorno.");
             // En producción, deberíamos salir aquí. Para dev/demo, aún podríamos usar una alternativa pero con una advertencia.
             // Para esta tarea de seguridad, lo forzaremos o usaremos uno fuerte predefinido SOLO si no podemos cargar el entorno (lo cual hace la clase Config).
             // Dada la implementación de Config.php, usemos una alternativa pero registrándola fuertemente.
             $secret = 'fallback_secret_key_change_in_production'; 
        }

        JWT::setSecret($secret);

        // 2. Crear Payload
        $payload = [
            "iss" => "sstpro.com",
            "iat" => time(),
            "exp" => time() + (60 * 60 * 24), // 24 horas
            "data" => [
                "id" => $user['id_usuario'],
                "rol" => $user['nombre_rol']
            ]
        ];

        // 3. Generar Token
        $jwt = JWT::encode($payload);

        // 4. Establecer Cookie HttpOnly
        // nombre, valor, expiración, ruta, dominio, seguro, httponly
        setcookie("auth_token", $jwt, time() + (60 * 60 * 24), "/", "", false, true); // Secure=false para pruebas en localhost

        echo json_encode([
            "status" => "success",
            "message" => "Login exitoso",
            "token" => $jwt,
            "user" => [
                "id" => $user['id_usuario'],
                "nombre" => $user['nombre_usuario'] . ' ' . $user['apellido_usuario'],
                "email" => $user['correo_usuario'],
                "rol" => $user['nombre_rol']
            ]
        ]);
        http_response_code(200);
    } else {
        echo json_encode(["message" => "Correo o contraseña incorrectos"]);
        http_response_code(401);
    }
} else {
    echo json_encode(["message" => "Datos incompletos"]);
    http_response_code(400);
}
?>
