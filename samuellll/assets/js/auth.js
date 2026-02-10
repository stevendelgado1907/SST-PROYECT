// assets/js/auth.js

(function () {
    // 1. Evitar la navegación hacia atrás a esta página después de cerrar sesión
    // Añadimos un estado ficticio para que "Atrás" se mantenga en la página actual (deshabilitando efectivamente el retroceso)
    history.pushState(null, null, location.href);
    window.onpopstate = function () {
        history.go(1);
    };

    // 2. Verificar la sesión a través de la API del Backend (Comprobación de Cookie HttpOnly)
    // Se ejecuta inmediatamente cuando el script se carga en el <head>
    async function verifySession() {
        try {
            // Buscar la ruta raíz basada en la ubicación actual
            // Si está en pages/, la raíz es ../backend. Si está en la raíz, es backend/
            const pathToBackend = window.location.pathname.includes('/pages/')
                ? '../backend/api/auth/verify.php'
                : 'backend/api/auth/verify.php';

            const loginPath = window.location.pathname.includes('/pages/')
                ? 'login.html'
                : 'pages/login.html';

            const response = await fetch(pathToBackend, {
                method: 'GET',
                cache: 'no-store' // Sin caché estricto para esta comprobación
            });

            if (response.status !== 200) {
                // Sesión inválida - Redirigir inmediatamente
                console.warn('Sesión inválida, redirigiendo al login...');
                window.location.replace(loginPath);
            } else {
                // Sesión válida
                const data = await response.json();
                console.log('Session verified:', data.user.nombre);
                // Opcionalmente actualizar la información del usuario en localStorage si es necesario para la interfaz, 
                // pero la confianza proviene de la Cookie. 
                // Podemos refrescar la información del usuario aquí si lo deseamos.
                localStorage.setItem('user', JSON.stringify(data.user));
            }
        } catch (e) {
            console.error('Auth verification failed:', e);
            // En caso de fallo (fail-safe)
            const loginPath = window.location.pathname.includes('/pages/')
                ? 'login.html'
                : 'pages/login.html';
            window.location.replace(loginPath);
        }
    }

    verifySession();
})();
