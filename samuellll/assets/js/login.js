// assets/js/login.js

document.addEventListener('DOMContentLoaded', function () {
    console.log("Script de login cargado");

    const loginForm = document.getElementById('loginForm');

    if (loginForm) {
        loginForm.addEventListener('submit', async function (e) {
            e.preventDefault();
            console.log("Enviando formulario de login...");

            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            const errorMessage = document.getElementById('errorMessage');
            const submitBtn = document.querySelector('.btn-login');

            // Retroalimentación visual
            submitBtn.disabled = true;
            submitBtn.textContent = "Verificando...";
            errorMessage.style.display = 'none';

            try {
                // Asegurar que la ruta sea correcta relativa al archivo HTML (pages/login.html -> ../backend)
                const response = await fetch('../backend/api/auth/login.php', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ email: email, password: password })
                });

                console.log("Estado de la respuesta:", response.status);

                let data;
                try {
                    data = await response.json();
                } catch (jsonError) {
                    throw new Error("Respuesta del servidor no es JSON válido.");
                }

                if (response.ok) {
                    console.log("Login exitoso");
                    // Cookie auth_token (HttpOnly) + token en localStorage como fallback para fetch
                    if (data.token) localStorage.setItem('token', data.token);
                    localStorage.setItem('user', JSON.stringify(data.user));

                    // Reemplazar el historial para evitar volver al login con el botón atrás
                    window.location.replace('../dashboard.html');
                } else {
                    console.warn("Login fallido:", data.message);
                    errorMessage.textContent = data.message || 'Error al iniciar sesión';
                    errorMessage.style.display = 'block';

                    submitBtn.disabled = false;
                    submitBtn.textContent = "Iniciar Sesión";

                    setTimeout(() => {
                        errorMessage.style.display = 'none';
                    }, 5000);
                }
            } catch (error) {
                console.error('Error de red o de parseo:', error);
                errorMessage.textContent = 'Error de conexión: ' + error.message;
                errorMessage.style.display = 'block';

                submitBtn.disabled = false;
                submitBtn.textContent = "Iniciar Sesión";
            }
        });
    } else {
        console.error("LoginForm no encontrado en el DOM");
    }
});
