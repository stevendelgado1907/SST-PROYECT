<?php
// backend/api/users/update.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once '../../config/Database.php';
require_once '../../api/middleware/AuthMiddleware.php';

AuthMiddleware::validate();

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (
    !empty($data->id) &&
    !empty($data->name) &&
    !empty($data->lastName) &&
    !empty($data->email) &&
    !empty($data->role) &&
    !empty($data->status)
) {
    try {
        // Password update is optional
        $passwordSet = !empty($data->password);
        
        // Validaciones backend coherentes con BD
        // Validar formato email (BD: VARCHAR(150) UNIQUE)
        if (!filter_var($data->email, FILTER_VALIDATE_EMAIL)) {
            http_response_code(400);
            echo json_encode(["message" => "Correo electrónico inválido."]);
            exit;
        }
        if (strlen($data->email) > 150) {
            http_response_code(400);
            echo json_encode(["message" => "El correo no puede exceder 150 caracteres."]);
            exit;
        }

        // Validar contraseña si se proporciona
        if ($passwordSet) {
            if (strlen($data->password) < 8) {
                http_response_code(400);
                echo json_encode(["message" => "La contraseña debe tener al menos 8 caracteres."]);
                exit;
            }
            if (!preg_match('/[A-Z]/', $data->password) || !preg_match('/[0-9]/', $data->password)) {
                http_response_code(400);
                echo json_encode(["message" => "La contraseña debe contener al menos una mayúscula y un número."]);
                exit;
            }
        }

        // Validar rol (BD: FK a tab_roles, esperamos 1 o 2)
        $allowedRoles = ['1', '2', 1, 2];
        if (!in_array($data->role, $allowedRoles, true)) {
            http_response_code(400);
            echo json_encode(["message" => "Rol inválido. Debe ser 1 (ADMINISTRADOR) o 2 (SUPERVISOR)."]);
            exit;
        }

        // Validar estado (BD: VARCHAR(50) DEFAULT 'ACTIVO')
        $allowedStatus = ['ACTIVO', 'INACTIVO'];
        if (!in_array($data->status, $allowedStatus)) {
            http_response_code(400);
            echo json_encode(["message" => "Estado inválido. Debe ser ACTIVO o INACTIVO."]);
            exit;
        }

        // Validar longitudes según BD
        if (strlen($data->name) > 100 || strlen($data->lastName) > 100) {
            http_response_code(400);
            echo json_encode(["message" => "Nombre o apellido excede la longitud permitida (100 caracteres)."]);
            exit;
        }

        // Verificar si el email ya existe para otro usuario
        $checkEmail = $db->prepare("SELECT id_usuario FROM tab_usuarios WHERE correo_usuario = :email AND id_usuario != :id");
        $checkEmail->bindParam(":email", $data->email);
        $checkEmail->bindParam(":id", $data->id);
        $checkEmail->execute();
        if ($checkEmail->rowCount() > 0) {
            http_response_code(400);
            echo json_encode(["message" => "El correo electrónico ya está registrado para otro usuario."]);
            exit;
        }

        $query = "UPDATE tab_usuarios
                SET
                    nombre_usuario = :name,
                    apellido_usuario = :lastname,
                    correo_usuario = :email,
                    id_rol = :role,
                    estado_usuario = :status" . 
                    ($passwordSet ? ", pass_hash = :password" : "") . 
                " WHERE id_usuario = :id";

        $stmt = $db->prepare($query);

        // Sanitize
        $data->id = htmlspecialchars(strip_tags($data->id));
        $data->name = htmlspecialchars(strip_tags($data->name));
        $data->lastName = htmlspecialchars(strip_tags($data->lastName));
        $data->email = htmlspecialchars(strip_tags($data->email));
        $data->role = htmlspecialchars(strip_tags($data->role));
        $data->status = htmlspecialchars(strip_tags($data->status));

        // Bind
        $stmt->bindParam(":id", $data->id);
        $stmt->bindParam(":name", $data->name);
        $stmt->bindParam(":lastname", $data->lastName);
        $stmt->bindParam(":email", $data->email);
        $stmt->bindParam(":role", $data->role);
        $stmt->bindParam(":status", $data->status);

        if ($passwordSet) {
            $passwordHash = password_hash($data->password, PASSWORD_BCRYPT);
            $stmt->bindParam(":password", $passwordHash);
        }

        if ($stmt->execute()) {
            http_response_code(200);
            echo json_encode(["message" => "Usuario actualizado exitosamente."]);
        } else {
            throw new Exception("Error al actualizar el usuario.");
        }
    } catch (Exception $e) {
        http_response_code(503);
        echo json_encode(["message" => "Error al actualizar: " . $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["message" => "Datos incompletos."]);
}
?>
