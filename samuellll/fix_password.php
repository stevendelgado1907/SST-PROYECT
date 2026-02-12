<?php
// fix_password.php
require_once 'backend/config/Database.php';

$database = new Database();
$db = $database->getConnection();

$email = 'admin@sst.com';
$password = 'Admin123';

// Check if Argon2id is available
if (defined('PASSWORD_ARGON2ID')) {
    $algo = PASSWORD_ARGON2ID;
    $algoName = 'Argon2id';
} else {
    $algo = PASSWORD_DEFAULT;
    $algoName = 'BCRYPT (Argon2id no soportado en este PHP)';
}

$newHash = password_hash($password, $algo);

echo "Intentando actualizar contraseña para: $email<br>";
echo "Algoritmo seleccionado: $algoName<br>";
echo "Nueva contraseña texto plano: $password<br>";
echo "Nuevo Hash generado: $newHash<br><br>";

try {
    // Verificar si el usuario existe
    $check = "SELECT id_usuario FROM tab_usuarios WHERE correo_usuario = :email";
    $stmtCheck = $db->prepare($check);
    $stmtCheck->bindParam(':email', $email);
    $stmtCheck->execute();

    if ($stmtCheck->rowCount() > 0) {
        // Actualizar
        $query = "UPDATE tab_usuarios SET pass_hash = :hash WHERE correo_usuario = :email";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':hash', $newHash);
        $stmt->bindParam(':email', $email);
        
        if ($stmt->execute()) {
            echo "<h1>¡ÉXITO!</h1>";
            echo "La contraseña ha sido actualizada correctamente en la base de datos.<br>";
            echo "Ahora puedes intentar iniciar sesión con <b>$password</b>";
        } else {
            echo "<h1>ERROR</h1>";
            echo "No se pudo actualizar la contraseña.";
        }
    } else {
        echo "<h1>ERROR</h1>";
        echo "El usuario $email no existe en la tabla tab_usuarios.";
    }

} catch (PDOException $e) {
    echo "Error de base de datos: " . $e->getMessage();
}
?>
