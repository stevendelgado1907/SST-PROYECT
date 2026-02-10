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

$required = ['name', 'address', 'phone'];
foreach ($required as $f) {
    if (empty($data->$f)) {
        http_response_code(400);
        echo json_encode(["message" => "Datos incompletos. Campo requerido: " . $f]);
        exit;
    }
}

try {
    $qMax = "SELECT COALESCE(MAX(id_eps), 0) + 1 as next_id FROM tab_eps";
    $st = $db->query($qMax);
    $nextId = $st->fetch(PDO::FETCH_ASSOC)['next_id'];

    $q = "INSERT INTO tab_eps (id_eps, nom_eps, direccion_eps, tel_eps, correo_eps) 
          VALUES (:id, :name, :address, :phone, :email)";
    $stmt = $db->prepare($q);
    
    $name = htmlspecialchars(strip_tags($data->name));
    $address = htmlspecialchars(strip_tags($data->address));
    $phone = htmlspecialchars(strip_tags($data->phone));
    $email = !empty($data->email) ? htmlspecialchars(strip_tags($data->email)) : null;

    $stmt->bindParam(":id", $nextId);
    $stmt->bindParam(":name", $name);
    $stmt->bindParam(":address", $address);
    $stmt->bindParam(":phone", $phone);
    $stmt->bindParam(":email", $email);

    if ($stmt->execute()) {
        http_response_code(201);
        echo json_encode(["message" => "EPS creada exitosamente.", "id" => (int)$nextId]);
    } else {
        throw new Exception("Error al insertar.");
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
