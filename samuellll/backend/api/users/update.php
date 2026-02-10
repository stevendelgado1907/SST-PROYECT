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
        // La actualización de contraseña es opcional
        $passwordSet = !empty($data->password);
        
        $query = "UPDATE tab_usuarios
                SET
                    nom_usuario = :name,
                    ape_usuario = :lastname,
                    correo_usuario = :email,
                    id_rol = :role,
                    estado_usuario = :status" . 
                    ($passwordSet ? ", pass_usuario = :password" : "") . 
                " WHERE id_usuario = :id";

        $stmt = $db->prepare($query);

        // Sanear datos
        $data->id = htmlspecialchars(strip_tags($data->id));
        $data->name = htmlspecialchars(strip_tags($data->name));
        $data->lastName = htmlspecialchars(strip_tags($data->lastName));
        $data->email = htmlspecialchars(strip_tags($data->email));
        $data->role = htmlspecialchars(strip_tags($data->role));
        $data->status = htmlspecialchars(strip_tags($data->status));

        // Vincular parámetros (Bind)
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
