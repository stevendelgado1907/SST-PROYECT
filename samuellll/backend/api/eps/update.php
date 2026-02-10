<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

require_once '../../config/Database.php';
require_once '../../api/middleware/AuthMiddleware.php';

AuthMiddleware::validate();

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (empty($data->id)) {
    http_response_code(400);
    echo json_encode(["message" => "ID requerido."]);
    exit;
}

$required = ['name', 'address', 'phone'];
foreach ($required as $f) {
    if (empty($data->$f)) {
        http_response_code(400);
        echo json_encode(["message" => "Datos incompletos."]);
        exit;
    }
}

try {
    $q = "UPDATE tab_eps SET nom_eps = :name, direccion_eps = :address, tel_eps = :phone, correo_eps = :email WHERE id_eps = :id";
    $stmt = $db->prepare($q);
    
    $id = (int)$data->id;
    $name = htmlspecialchars(strip_tags($data->name));
    $address = htmlspecialchars(strip_tags($data->address));
    $phone = htmlspecialchars(strip_tags($data->phone));
    $email = !empty($data->email) ? htmlspecialchars(strip_tags($data->email)) : null;

    $stmt->bindParam(":id", $id);
    $stmt->bindParam(":name", $name);
    $stmt->bindParam(":address", $address);
    $stmt->bindParam(":phone", $phone);
    $stmt->bindParam(":email", $email);

    if ($stmt->execute()) {
        echo json_encode(["message" => "EPS actualizada exitosamente."]);
    } else {
        throw new Exception("Error al actualizar.");
    }
} catch (PDOException $e) {
    if ($e->getCode() == 23505) {
        http_response_code(400);
        echo json_encode(["message" => "El nombre de EPS ya existe."]);
    } else {
        http_response_code(500);
        echo json_encode(["message" => $e->getMessage()]);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => $e->getMessage()]);
}
