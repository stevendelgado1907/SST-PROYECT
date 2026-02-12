<?php
// setup_admin.php
header("Content-Type: text/html; charset=UTF-8");
require_once 'backend/config/Database.php';

$database = new Database();
$db = $database->getConnection();

// --- CONFIGURACIÓN DEL SUPER ADMINISTRADOR ---
// Se obtiene desde variables de entorno (.env)
// --- CONFIGURACIÓN DEL SUPER ADMINISTRADOR ---
// Se obtiene desde variables de entorno (.env)
require_once 'backend/config/Config.php';

$id_usuario = Config::get('ADMIN_ID', 1);
$correo = Config::get('ADMIN_EMAIL', 'admin@sst.com');
$password_plano = Config::get('ADMIN_PASSWORD', 'Admin123'); 
$nombre = Config::get('ADMIN_NAME', 'Samuel'); 
$apellido = Config::get('ADMIN_LASTNAME', 'Administrador');
$id_rol = Config::get('ADMIN_ROLE', 1); 
$estado = 'ACTIVO';

// 1. ENCRIPTACIÓN (HASHING)
// Detectamos si el servidor soporta Argon2id (más seguro), si no, usamos BCRYPT (estándar)
$algo = defined('PASSWORD_ARGON2ID') ? PASSWORD_ARGON2ID : PASSWORD_DEFAULT;
$pass_hash = password_hash($password_plano, $algo);

echo "<h2>Configuración de Administrador</h2>";
echo "<ul>";
echo "<li><b>Usuario ID:</b> $id_usuario</li>";
echo "<li><b>Correo:</b> $correo</li>";
echo "<li><b>Contraseña texto plano:</b> $password_plano (Esta NO se guarda)</li>";
echo "<li><b>Hash generado (Encriptado):</b> $pass_hash (Esto SÍ se guarda)</li>";
echo "<li><b>Algoritmo usado:</b> " . ($algo == PASSWORD_ARGON2ID ? 'Argon2id' : 'BCRYPT') . "</li>";
echo "</ul>";

try {
    // Verificar si ya existe
    $checkSql = "SELECT id_usuario FROM tab_usuarios WHERE id_usuario = :id OR correo_usuario = :email";
    $stmtCheck = $db->prepare($checkSql);
    $stmtCheck->bindParam(':id', $id_usuario);
    $stmtCheck->bindParam(':email', $correo);
    $stmtCheck->execute();

    if ($stmtCheck->rowCount() > 0) {
        // ACTUALIZAR (UPDATE)
        echo "<p>El usuario ya existe. Actualizando credenciales...</p>";
        $sql = "UPDATE tab_usuarios SET 
                pass_hash = :hash, 
                nombre_usuario = :nombre, 
                apellido_usuario = :apellido, 
                id_rol = :rol,
                estado_usuario = :estado
                WHERE id_usuario = :id OR correo_usuario = :email";
    } else {
        // CREAR (INSERT)
        echo "<p>El usuario no existe. Creando nuevo registro...</p>";
        $sql = "INSERT INTO tab_usuarios 
                (id_usuario, correo_usuario, pass_hash, id_rol, nombre_usuario, apellido_usuario, estado_usuario) 
                VALUES 
                (:id, :email, :hash, :rol, :nombre, :apellido, :estado)";
    }

    $stmt = $db->prepare($sql);
    
    // Bind parameters
    $stmt->bindParam(':hash', $pass_hash);
    $stmt->bindParam(':nombre', $nombre);
    $stmt->bindParam(':apellido', $apellido);
    $stmt->bindParam(':rol', $id_rol);
    $stmt->bindParam(':estado', $estado);
    $stmt->bindParam(':id', $id_usuario);
    $stmt->bindParam(':email', $correo);

    if ($stmt->execute()) {
        echo "<h3 style='color: green;'>¡ÉXITO! Usuario Administrador configurado correctamente.</h3>";
        echo "<p>Ahora el sistema funciona así:</p>";
        echo "<ol>";
        echo "<li>Vas al login e ingresas <b>$password_plano</b>.</li>";
        echo "<li>El sistema recibe ese texto plano.</li>";
        echo "<li>El sistema busca en la base de datos y encuentra el hash: <b>" . substr($pass_hash, 0, 15) . "...</b></li>";
        echo "<li>La función <code>password_verify()</code> comprueba matemáticamente si coinciden.</li>";
        echo "<li>Si coinciden, ¡te deja entrar!</li>";
        echo "</ol>";
        echo "<br><a href='login.html'>Ir a Iniciar Sesión</a>";
    } else {
        echo "<h3 style='color: red;'>ERROR al guardar en base de datos.</h3>";
        print_r($stmt->errorInfo());
    }

} catch (PDOException $e) {
    echo "Excepción: " . $e->getMessage();
}
?>
