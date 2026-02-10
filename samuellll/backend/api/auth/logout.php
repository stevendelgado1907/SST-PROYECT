<?php
// backend/api/auth/logout.php
// Clear cookie
setcookie("auth_token", "", time() - 3600, "/", "", false, true);

// Redirect to Landing Page (relative to this file: ../../../index.html)
header("Location: ../../../index.html");
exit;
?>
