<?php
echo "<h1>Diagnóstico Extremo de PostgreSQL</h1>";

// 1. Ver si la extensión está cargada
echo "<h2>1. Verificando extensión PHP:</h2>";
if (extension_loaded('pdo_pgsql')) {
    echo "<p style='color:green'>✅ Extensión 'pdo_pgsql' cargada correctamente.</p>";
} else {
    echo "<p style='color:red'>❌ Extensión 'pdo_pgsql' NO está cargada.</p>";
    echo "<p>Verifica que <code>extension=pdo_pgsql</code> no tenga punto y coma en <code>php.ini</code></p>";
}

// 2. Ver drivers
echo "<h2>2. Drivers PDO detectados:</h2>";
$drivers = PDO::getAvailableDrivers();
if (in_array('pgsql', $drivers)) {
    echo "<p style='color:green'>✅ Driver 'pgsql' detectado en PDO.</p>";
} else {
    echo "<p style='color:red'>❌ Driver 'pgsql' NO detectado en PDO.</p>";
}

echo "<pre>";
print_r($drivers);
echo "</pre>";

// 3. Ruta del php.ini
echo "<h2>3. Archivo de configuración usado:</h2>";
echo "<p>" . php_ini_loaded_file() . "</p>";

echo "<h2>💡 SOLUCIÓN DEFINITIVA (Si todo lo anterior falla):</h2>";
echo "<ol>";
echo "<li>Abre el Panel de XAMPP</li>";
echo "<li>En Apache, click en <b>Config > Apache (httpd.conf)</b></li>";
echo "<li>Pega estas 3 líneas AL FINAL DEL ARCHIVO y guarda:</li>";
echo "</ol>";
echo "<pre style='background:#eee;padding:10px;border:1px solid #999'>";
echo "LoadFile \"C:/xampp/php/libpq.dll\"\n";
echo "LoadFile \"C:/xampp/php/libintl-8.dll\"\n";
echo "LoadFile \"C:/xampp/php/libiconv-2.dll\"";
echo "</pre>";
echo "<p>Reinicia Apache después de esto.</p>";
?>
