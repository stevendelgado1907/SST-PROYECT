// assets/js/cookies.js

document.addEventListener('DOMContentLoaded', function () {
    checkCookieConsent();
});

function checkCookieConsent() {
    if (!localStorage.getItem('cookieConsent')) {
        const modalHtml = `
            <div id="cookieModal" class="cookie-modal active">
                <div class="cookie-content">
                    <h3>🍪 Uso de Cookies</h3>
                    <p>Este sistema utiliza cookies técnicas y de sesión para garantizar su funcionamiento y seguridad. Al continuar navegando, aceptas su uso.</p>
                    <div class="cookie-actions">
                        <button id="acceptCookies" class="btn btn-primary" style="padding: 8px 16px; font-size: 0.85em;">Entendido</button>
                    </div>
                </div>
            </div>
        `;
        document.body.insertAdjacentHTML('beforeend', modalHtml);

        const btn = document.getElementById('acceptCookies');
        if (btn) {
            btn.addEventListener('click', function () {
                localStorage.setItem('cookieConsent', 'true');
                const modal = document.getElementById('cookieModal');
                if (modal) modal.remove();
            });
        }
    }
}
