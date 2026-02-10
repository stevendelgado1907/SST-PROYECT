// assets/js/auth.js

(function () {
    // 1. Prevent back navigation to this page after logout
    // Push a dummy state so "Back" stays on the current page (effectively disabling back)
    history.pushState(null, null, location.href);
    window.onpopstate = function () {
        history.go(1);
    };

    // 2. Verify Session via Backend API (HttpOnly Cookie Check)
    // Runs immediately when script is loaded in <head>
    async function verifySession() {
        try {
            // Find root path based on current location
            // If in pages/, root is ../backend. If in root, it's backend/
            const pathToBackend = window.location.pathname.includes('/pages/')
                ? '../backend/api/auth/verify.php'
                : 'backend/api/auth/verify.php';

            const loginPath = window.location.pathname.includes('/pages/')
                ? 'login.html'
                : 'pages/login.html';

            const response = await fetch(pathToBackend, {
                method: 'GET',
                cache: 'no-store' // Strict no-cache for this check
            });

            if (response.status !== 200) {
                // Invalid Session - Redirect immediately
                console.warn('Session invalid, redirecting to login...');
                window.location.replace(loginPath);
            } else {
                // Session Valid
                const data = await response.json();
                console.log('Session verified:', data.user.nombre);
                // Optionally update localStorage user info if needed for UI, 
                // but trust comes from Cookie. 
                // We can refresh user info here if we want.
                localStorage.setItem('user', JSON.stringify(data.user));
            }
        } catch (e) {
            console.error('Auth verification failed:', e);
            // Fail safe
            const loginPath = window.location.pathname.includes('/pages/')
                ? 'login.html'
                : 'pages/login.html';
            window.location.replace(loginPath);
        }
    }

    verifySession();
})();
