// assets/js/login.js

document.addEventListener('DOMContentLoaded', function () {
    console.log("Login script loaded");

    const loginForm = document.getElementById('loginForm');

    if (loginForm) {
        loginForm.addEventListener('submit', async function (e) {
            e.preventDefault();
            console.log("Submitting login form...");

            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            const errorMessage = document.getElementById('errorMessage');
            const submitBtn = document.querySelector('.btn-login');

            // Visual feedback
            submitBtn.disabled = true;
            submitBtn.textContent = "Verificando...";
            errorMessage.style.display = 'none';

            try {
                // Ensure the path is correct relative to the HTML file (pages/login.html -> ../backend)
                const response = await fetch('../backend/api/auth/login.php', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ email: email, password: password })
                });

                console.log("Response status:", response.status);

                let data;
                try {
                    data = await response.json();
                } catch (jsonError) {
                    throw new Error("Respuesta del servidor no es JSON válido.");
                }

                if (response.ok) {
                    console.log("Login successful");
                    // Cookie auth_token (HttpOnly) + token en localStorage como fallback para fetch
                    if (data.token) localStorage.setItem('token', data.token);
                    localStorage.setItem('user', JSON.stringify(data.user));

                    // Replace history to prevent going back to login
                    window.location.replace('../dashboard.html');
                } else {
                    console.warn("Login failed:", data.message);
                    errorMessage.textContent = data.message || 'Error al iniciar sesión';
                    errorMessage.style.display = 'block';

                    submitBtn.disabled = false;
                    submitBtn.textContent = "Iniciar Sesión";

                    setTimeout(() => {
                        errorMessage.style.display = 'none';
                    }, 5000);
                }
            } catch (error) {
                console.error('Network or Parsing Error:', error);
                errorMessage.textContent = 'Error de conexión: ' + error.message;
                errorMessage.style.display = 'block';

                submitBtn.disabled = false;
                submitBtn.textContent = "Iniciar Sesión";
            }
        });
    } else {
        console.error("LoginForm not found in DOM");
    }
});
