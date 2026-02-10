<?php
// backend/api/users/create.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once '../../config/Database.php';

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

        // Sanitize and Bind
        $name = htmlspecialchars(strip_tags($data->name));
        $lastName = htmlspecialchars(strip_tags($data->lastName));
        $email = htmlspecialchars(strip_tags($data->email));
        $role = htmlspecialchars(strip_tags($data->role));
        $status = !empty($data->status) ? htmlspecialchars(strip_tags($data->status)) : 'ACTIVO';

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
