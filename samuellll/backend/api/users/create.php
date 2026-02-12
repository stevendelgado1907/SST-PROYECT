<?php
// backend/api/users/create.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once '../../config/Database.php';
require_once '../../api/middleware/AuthMiddleware.php';

// Proteger creación de usuarios: solo usuarios autenticados pueden crear usuarios
AuthMiddleware::validate();

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (
    !empty($data->name) &&
    !empty($data->lastName) &&
    !empty($data->email) &&
    !empty($data->password) &&
    !empty($data->role)
) {
    try {
        // 1. Calculate next ID (since schema implies simple integer PK without explicit SERIAL/AUTO_INCREMENT info)
        $queryMax = "SELECT MAX(id_usuario) as max_id FROM tab_usuarios";
        $stmtMax = $db->prepare($queryMax);
        $stmtMax->execute();
        $rowMax = $stmtMax->fetch(PDO::FETCH_ASSOC);
        $nextId = ($rowMax['max_id'] ?? 0) + 1;

        // 2. Hash Password
        $passwordHash = password_hash($data->password, PASSWORD_BCRYPT);

        // 3. Insert User
        $query = "INSERT INTO tab_usuarios 
                    (id_usuario, nombre_usuario, apellido_usuario, correo_usuario, pass_hash, id_rol, estado_usuario)
                  VALUES
                    (:id, :nombre, :apellido, :email, :pass_hash, :rol, :estado)";

        $stmt = $db->prepare($query);

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

        // Validar contraseña (mínimo 8 caracteres, al menos una mayúscula y un número)
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

        // Validar rol (BD: FK a tab_roles, esperamos 1 o 2)
        $allowedRoles = ['1', '2', 1, 2];
        if (!in_array($data->role, $allowedRoles, true)) {
            http_response_code(400);
            echo json_encode(["message" => "Rol inválido. Debe ser 1 (ADMINISTRADOR) o 2 (SUPERVISOR)."]);
            exit;
        }

        // Validar estado (BD: VARCHAR(50) DEFAULT 'ACTIVO')
        $allowedStatus = ['ACTIVO', 'INACTIVO'];
        $status = !empty($data->status) ? htmlspecialchars(strip_tags($data->status)) : 'ACTIVO';
        if (!in_array($status, $allowedStatus)) {
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

        // Sanitize and Bind
        $name = htmlspecialchars(strip_tags($data->name));
        $lastName = htmlspecialchars(strip_tags($data->lastName));
        $email = htmlspecialchars(strip_tags($data->email));
        $role = htmlspecialchars(strip_tags($data->role));

        $stmt->bindParam(":id", $nextId);
        $stmt->bindParam(":nombre", $name);
        $stmt->bindParam(":apellido", $lastName);
        $stmt->bindParam(":email", $email);
        $stmt->bindParam(":pass_hash", $passwordHash);
        $stmt->bindParam(":rol", $role);
        $stmt->bindParam(":estado", $status);

        if ($stmt->execute()) {
            http_response_code(201);
            echo json_encode(["message" => "Usuario creado exitosamente.", "id" => $nextId]);
        } else {
            http_response_code(503);
            echo json_encode(["message" => "No se pudo crear el usuario."]);
        }
    } catch (PDOException $e) {
        if ($e->getCode() == 23505) { // Unique violation in Postgres
             http_response_code(400);
             echo json_encode(["message" => "El correo ya está registrado."]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Error de base de datos: " . $e->getMessage()]);
        }
    }
} else {
    http_response_code(400);
    echo json_encode(["message" => "Datos incompletos."]);
}
?>
