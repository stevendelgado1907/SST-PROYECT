
// Globals for EPP and Inventory
let eppList = [];
let invList = [];
let workers = [];
let risks = [];
let usersList = [];
let arlList = [];
let epsList = [];
let ipsList = [];
let currentUser = JSON.parse(localStorage.getItem('user'));

// Modal Helpers
function openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.style.display = 'flex'; // Enforce visibility
        // Small timeout to allow display change to register before opacity transition
        setTimeout(() => {
            modal.classList.add('active');
        }, 10);
    }
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.remove('active');
        // Wait for transition to finish before hiding
        setTimeout(() => {
            modal.style.display = 'none';
        }, 300);
    }
}

// Window click to close modals
// Window click to close modals
window.onclick = function (event) {
    if (event.target.classList.contains('modal')) {
        closeModal(event.target.id);
    }
}

// Cerrar sesión con confirmación
window.confirmLogout = function (event) {
    if (event) event.preventDefault();
    if (!confirm('¿Está seguro de cerrar sesión?')) return false;
    localStorage.removeItem('user');
    localStorage.removeItem('token');
    window.location.href = 'backend/api/auth/logout.php';
    return false;
}

// Verificar autenticación
if (!currentUser) {
    // Si estamos en una subpágina, la ruta podría necesitar ajuste, pero asumimos estructura plana por ahora
    window.location.href = 'pages/login.html';
}

// Cargar datos iniciales
document.addEventListener('DOMContentLoaded', function () {
    loadUserData();
    // loadSampleData(); // Ya no es necesario, datos cargados en data.js
    setupEventListeners();
    updateDate();
    setupNavigation();

    // Inicializar renders si existen las tablas correspondientes en la página actual
    if (document.getElementById('usersTable')) renderUsersTable();
    if (document.getElementById('workersTable')) renderWorkersTable();
    if (document.getElementById('inventarioTable')) renderInventoryTable();
    if (document.getElementById('risksTable')) renderRisksTable();
    if (document.getElementById('arlTable')) renderHealthEntities();

    // Nueva función para cargar estadísticas reales del dashboard
    if (document.getElementById('totalWorkers')) {
        loadDashboardStats();
        loadRecentActivity(); // Cargar actividad reciente
    }

    updateStatistics(); // Mantener para fallback o tablas locales
});

async function loadDashboardStats() {
    try {
        const response = await fetch(`backend/api/dashboard/stats.php?t=${new Date().getTime()}`, { headers: getAuthHeaders() });
        if (response.ok) {
            const stats = await response.json();
            if (document.getElementById('totalWorkers')) document.getElementById('totalWorkers').innerText = stats.totalWorkers;
            // Para EPP, stats.php devuelve totalEpp (suma stock). 
            if (document.getElementById('totalEpp')) document.getElementById('totalEpp').innerText = stats.totalEpp || 0;
            if (document.getElementById('totalRisks')) document.getElementById('totalRisks').innerText = stats.totalRisks;
            if (document.getElementById('expiringSoon')) {
                document.getElementById('expiringSoon').innerText = stats.expiringSoon;
                // Resaltar si hay EPP por vencer
                const expiringCard = document.getElementById('expiringCard');
                if (stats.expiringSoon > 0 && expiringCard) {
                    expiringCard.style.borderLeftColor = '#ef4444';
                    expiringCard.style.backgroundColor = '#fef2f2';
                }
            }
            
            // Mostrar alertas si hay problemas
            const alertsContainer = document.getElementById('dashboardAlerts');
            if (alertsContainer) {
                alertsContainer.innerHTML = '';
                if (stats.expiringSoon > 0) {
                    const alert = document.createElement('div');
                    alert.className = 'card';
                    alert.style.borderLeft = '4px solid #f59e0b';
                    alert.style.backgroundColor = '#fffbeb';
                    alert.innerHTML = `
                        <div style="display: flex; align-items: center; gap: 10px;">
                            <span style="font-size: 1.5em;">⚠️</span>
                            <div>
                                <strong>${stats.expiringSoon} EPP próximo${stats.expiringSoon > 1 ? 's' : ''} a vencer</strong>
                                <p style="margin: 5px 0 0 0; color: #666;">Hay equipos que vencen en los próximos 30 días. <a href="epp.html" style="color: #2563eb;">Ver detalles →</a></p>
                            </div>
                        </div>
                    `;
                    alertsContainer.appendChild(alert);
                }
                if (stats.lowStock > 0) {
                    const alert = document.createElement('div');
                    alert.className = 'card';
                    alert.style.borderLeft = '4px solid #ef4444';
                    alert.style.backgroundColor = '#fef2f2';
                    alert.style.marginTop = '10px';
                    alert.innerHTML = `
                        <div style="display: flex; align-items: center; gap: 10px;">
                            <span style="font-size: 1.5em;">📦</span>
                            <div>
                                <strong>${stats.lowStock} item${stats.lowStock > 1 ? 's' : ''} con stock bajo</strong>
                                <p style="margin: 5px 0 0 0; color: #666;">Hay productos que están en o por debajo del stock mínimo. <a href="inventario.html" style="color: #2563eb;">Ver inventario →</a></p>
                            </div>
                        </div>
                    `;
                    alertsContainer.appendChild(alert);
                }
            }
        } else {
            console.error("Error loading stats:", response.status);
        }
    } catch (e) {
        console.error("Error fetching dashboard stats:", e);
    }
}

async function loadRecentActivity() {
    const tbody = document.getElementById('recentActivity');
    if (!tbody) return;

    try {
        // Cargar datos recientes de diferentes módulos
        const [workersRes, eppRes, risksRes, invRes] = await Promise.all([
            fetch('backend/api/workers/read.php', { headers: getAuthHeaders() }).catch(() => null),
            fetch('backend/api/epp/read.php', { headers: getAuthHeaders() }).catch(() => null),
            fetch('backend/api/risks/read.php', { headers: getAuthHeaders() }).catch(() => null),
            fetch('backend/api/inventory/read.php', { headers: getAuthHeaders() }).catch(() => null)
        ]);

        const activities = [];

        // Trabajadores recientes (últimos 5)
        if (workersRes && workersRes.ok) {
            const workers = await workersRes.json();
            workers.slice(0, 5).forEach(w => {
                activities.push({
                    fecha: w.fecha_registro || w.startDate || new Date().toISOString().split('T')[0],
                    actividad: `Nuevo trabajador: ${w.name} ${w.lastName}`,
                    usuario: currentUser?.name || 'Sistema',
                    detalle: `Documento: ${w.id}`
                });
            });
        }

        // EPP recientes (últimos 5) - usando fecha_compra_epp como referencia
        if (eppRes && eppRes.ok) {
            const epps = await eppRes.json();
            epps.slice(0, 5).forEach(e => {
                activities.push({
                    fecha: e.buy_date || new Date().toISOString().split('T')[0],
                    actividad: `Nuevo EPP registrado: ${e.name}`,
                    usuario: currentUser?.name || 'Sistema',
                    detalle: `Referencia: ${e.reference}`
                });
            });
        }

        // Riesgos recientes (últimos 5) - no hay fecha en BD, usamos orden por ID
        if (risksRes && risksRes.ok) {
            const risks = await risksRes.json();
            risks.slice(0, 5).forEach(r => {
                activities.push({
                    fecha: new Date().toISOString().split('T')[0],
                    actividad: `Nuevo riesgo identificado: ${r.name}`,
                    usuario: currentUser?.name || 'Sistema',
                    detalle: `Nivel: ${r.level}`
                });
            });
        }

        // Ordenar por fecha (más reciente primero) y tomar los últimos 10
        activities.sort((a, b) => new Date(b.fecha) - new Date(a.fecha));
        const recentActivities = activities.slice(0, 10);

        tbody.innerHTML = '';
        if (recentActivities.length === 0) {
            tbody.innerHTML = '<tr><td colspan="4">No hay actividad reciente.</td></tr>';
            return;
        }

        recentActivities.forEach(act => {
            const row = document.createElement('tr');
            row.innerHTML = `
                <td>${act.fecha}</td>
                <td>${act.actividad}</td>
                <td>${act.usuario}</td>
                <td>${act.detalle}</td>
            `;
            tbody.appendChild(row);
        });
    } catch (e) {
        console.error("Error loading recent activity:", e);
        if (tbody) tbody.innerHTML = '<tr><td colspan="4">Error al cargar actividad reciente.</td></tr>';
    }
}

function loadUserData() {
    if (document.getElementById('userName')) document.getElementById('userName').textContent = currentUser.name;
    if (document.getElementById('userRole')) document.getElementById('userRole').textContent = currentUser.role;
    if (document.getElementById('welcomeName')) document.getElementById('welcomeName').textContent = currentUser.name.split(' ')[0];

    // Mostrar avatar con iniciales
    const initials = currentUser.name.split(' ').map(n => n[0]).join('').toUpperCase();
    if (document.getElementById('userAvatar')) document.getElementById('userAvatar').textContent = initials.substring(0, 2);

    // Ocultar botón agregar usuario si no es admin
    if (currentUser.role !== 'ADMINISTRADOR') {
        const addUserBtn = document.getElementById('addUserBtn');
        if (addUserBtn) addUserBtn.style.display = 'none';
    }

    // Cookie Consent Injection
    checkCookieConsent();
}

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

        document.getElementById('acceptCookies').addEventListener('click', function () {
            localStorage.setItem('cookieConsent', 'true');
            document.getElementById('cookieModal').remove();
        });
    }
}

function setupEventListeners() {
    // Logout logic handled by anchor tag in HTML

    // Formulario agregar usuario
    // Expose for global use
    window.addNewWorker = addNewWorker;

    if (addUserForm) {
        addUserForm.addEventListener('submit', function (e) {
            e.preventDefault();
            addNewUser();
        });
    }

    // Formulario agregar trabajador
    const addWorkerForm = document.getElementById('addWorkerForm');
    if (addWorkerForm) {
        addWorkerForm.addEventListener('submit', function (e) {
            e.preventDefault();
            saveWorker();
        });
    }

    // Formularios de Inventario y EPP:
    // Ahora el submit se maneja directamente desde el HTML con onsubmit="event.preventDefault(); saveInventory();"
    // y onsubmit="event.preventDefault(); saveEpp();", para garantizar que la acción siempre se dispare
    // aunque algún listener JS falle. Aquí no añadimos más listeners para evitar envíos duplicados.

    // Formularios ARL, EPS, IPS
    const arlForm = document.getElementById('arlForm');
    if (arlForm) arlForm.addEventListener('submit', function (e) { e.preventDefault(); saveArl(); });
    const epsForm = document.getElementById('epsForm');
    if (epsForm) epsForm.addEventListener('submit', function (e) { e.preventDefault(); saveEps(); });
    const ipsForm = document.getElementById('ipsForm');
    if (ipsForm) ipsForm.addEventListener('submit', function (e) { e.preventDefault(); saveIps(); });
}



function updateDate() {
    const now = new Date();
    const options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
    const dateElement = document.getElementById('currentDate');
    if (dateElement) dateElement.textContent = now.toLocaleDateString('es-ES', options);
}

function updateStatistics() {
    // Actualizar estadísticas en dashboard
    const totalWorkers = document.getElementById('totalWorkers');
    if (totalWorkers) totalWorkers.textContent = workers.length;

    const totalEpp = document.getElementById('totalEpp');
    if (totalEpp) totalEpp.textContent = invList.filter(e => e.stock > 0).length; // Use invList and check stock

    const totalRisks = document.getElementById('totalRisks');
    if (totalRisks) totalRisks.textContent = risks.length;

    const expiringSoon = document.getElementById('expiringSoon');
    if (expiringSoon) expiringSoon.textContent = eppList.filter(e => {
        // Simple check for expiring soon (e.g., within 30 days) if date lib available, else mock
        return false;
    }).length;

    // Actualizar reportes
    const assignedEppCount = document.getElementById('assignedEppCount');
    if (assignedEppCount) assignedEppCount.textContent = invList.filter(e => e.status !== 'DISPONIBLE').length;

    const expiredEppCount = document.getElementById('expiredEppCount');
    if (expiredEppCount) expiredEppCount.textContent = '0';

    const highRisksCount = document.getElementById('highRisksCount');
    if (highRisksCount) highRisksCount.textContent = risks.filter(r => r.level === 'ALTO' || r.level === 'MUY ALTO').length;

    const medicalExamsCount = document.getElementById('medicalExamsCount');
    if (medicalExamsCount) medicalExamsCount.textContent = workers.length;
}

// Helper para Headers (el token va en cookie auth_token; incluimos credentials para enviar cookies)
function getAuthHeaders() {
    const token = localStorage.getItem('token');
    return {
        'Content-Type': 'application/json',
        ...(token && { 'Authorization': `Bearer ${token}` })
    };
}

// Opciones base para fetch con API (envía cookies de sesión)
function getFetchOpts(method, body) {
    const opts = { method, headers: getAuthHeaders(), credentials: 'same-origin' };
    if (body !== undefined) opts.body = typeof body === 'string' ? body : JSON.stringify(body);
    return opts;
}

// -------------------------------------------------------------
// RENDER TABLES (API)
// -------------------------------------------------------------

async function renderUsersTable() {
    const tbody = document.getElementById('usersTable');
    if (!tbody) return;


    try {
        const response = await fetch('backend/api/users/read.php', {
            method: 'GET',
            headers: getAuthHeaders()
        });

        if (response.status === 401) { window.location.href = 'login.html'; return; }

        const data = await response.json();
        const usersData = Array.isArray(data) ? data : [];
        usersList = usersData; // Global for edit

        tbody.innerHTML = '';
        if (usersData.length === 0) {
            tbody.innerHTML = '<tr><td colspan="7">No hay usuarios registrados.</td></tr>';
            return;
        }

        usersData.forEach(user => {
            const row = document.createElement('tr');
            const isActive = user.status === 'ACTIVO';
            // Formatear último acceso
            let lastAccessFormatted = 'Nunca';
            if (user.lastAccess) {
                try {
                    const lastAccessDate = new Date(user.lastAccess);
                    lastAccessFormatted = lastAccessDate.toLocaleDateString('es-ES') + ' ' + lastAccessDate.toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' });
                } catch (e) {
                    lastAccessFormatted = user.lastAccess;
                }
            }
            row.innerHTML = `
                <td>${user.id}</td>
                <td>${user.fullName}</td>
                <td>${user.email}</td>
                <td><span class="role-badge ${user.role === 'ADMINISTRADOR' ? 'admin' : ''}">${user.role}</span></td>
                <td><span class="status-badge ${isActive ? 'status-active' : 'status-inactive'}">${user.status}</span></td>
                <td>${lastAccessFormatted}</td>
                <td>
                    ${currentUser && currentUser.data && currentUser.data.rol === 'ADMINISTRADOR' ? `
                    <button class="btn btn-primary btn-sm" onclick="editUser(${user.id})">✏️</button>
                    <button class="btn btn-danger btn-sm" onclick="deleteUser(${user.id})">🗑️</button>
                    ` : '<span style="color: grey;">Solo lectura</span>'}
                </td>
            `;
            tbody.appendChild(row);
        });
    } catch (error) {
        console.error('Error users:', error);
        tbody.innerHTML = '<tr><td colspan="7">Error al cargar usuarios.</td></tr>';
    }
}

async function renderEppTable() {
    const tbody = document.getElementById('eppTable');
    if (!tbody) return;
    tbody.innerHTML = '<tr><td colspan="8">Cargando EPP...</td></tr>';

    try {
        const response = await fetch('backend/api/epp/read.php', {
            method: 'GET',
            headers: getAuthHeaders()
        });

        if (response.status === 401) { window.location.href = 'pages/login.html'; return; }

        const data = await response.json();
        eppList = Array.isArray(data) ? data : [];

        tbody.innerHTML = '';
        if (eppList.length === 0) {
            tbody.innerHTML = '<tr><td colspan="8">No hay equipos registrados.</td></tr>';
            return;
        }

        eppList.forEach(item => {
            const row = document.createElement('tr');
            // Use specific class for status coloring
            const statusClass = item.status === 'DISPONIBLE' ? 'status-active' : 'status-inactive';
            
            // Formatear fecha de vencimiento y verificar si está por vencer
            let expDateFormatted = item.exp_date || 'N/A';
            let expDateClass = '';
            if (item.exp_date) {
                const expDate = new Date(item.exp_date);
                const today = new Date();
                const daysDiff = Math.ceil((expDate - today) / (1000 * 60 * 60 * 24));
                if (daysDiff < 0) {
                    expDateClass = 'style="color: #ef4444; font-weight: bold;"';
                    expDateFormatted = `${item.exp_date} (Vencido)`;
                } else if (daysDiff <= 30) {
                    expDateClass = 'style="color: #f59e0b; font-weight: bold;"';
                    expDateFormatted = `${item.exp_date} (${daysDiff} días)`;
                } else {
                    expDateFormatted = item.exp_date;
                }
            }

            row.innerHTML = `
                    <td>${item.id}</td>
                    <td>${item.name}</td>
                    <td>${item.reference}</td>
                    <td>${item.brand_name || 'N/A'}</td>
                    <td>${item.category_name || 'N/A'}</td>
                    <td ${expDateClass}>${expDateFormatted}</td>
                    <td><span class="status-badge ${statusClass}">${item.status}</span></td>
                    <td>
                        <button class="btn btn-primary btn-sm" onclick="editEpp(${item.id})">✏️</button>
                        <button class="btn btn-danger btn-sm" onclick="deleteEpp(${item.id})">🗑️</button>
                    </td>
                `;
            tbody.appendChild(row);
        });
    } catch (e) {
        console.error('Error loading EPP:', e);
        tbody.innerHTML = '<tr><td colspan="8">Error cargando EPP.</td></tr>';
    }
}

async function renderWorkersTable() {
    const tbody = document.getElementById('workersTable');
    if (!tbody) return;

    tbody.innerHTML = '<tr><td colspan="8">Cargando trabajadores...</td></tr>';

    try {
        const response = await fetch('backend/api/workers/read.php', {
            method: 'GET',
            headers: getAuthHeaders(),
            credentials: 'include'
        });

        if (response.status === 401) { window.location.href = 'pages/login.html'; return; }

        const data = await response.json();
        const workersData = Array.isArray(data) ? data : [];
        workers = workersData; // Update global for stats

        tbody.innerHTML = '';
        if (workersData.length === 0) {
            tbody.innerHTML = '<tr><td colspan="8">No hay trabajadores registrados.</td></tr>';
            return;
        }

        workersData.forEach(worker => {
            const row = document.createElement('tr');
            // Determinar estado según fecha de retiro (BD: fecha_retiro_trabajador)
            const isActive = !worker.fecha_retiro_trabajador || new Date(worker.fecha_retiro_trabajador) > new Date();
            const statusClass = isActive ? 'status-active' : 'status-inactive';
            const statusText = isActive ? 'ACTIVO' : 'RETIRADO';
            
            // Formatear fecha de ingreso
            const startDateFormatted = worker.startDate ? new Date(worker.startDate).toLocaleDateString('es-ES') : 'N/A';

            row.innerHTML = `
                <td>${worker.id}</td>
                <td>${worker.name} ${worker.lastName}</td>
                <td>${worker.position || 'Sin cargo'}</td>
                <td>${startDateFormatted}</td>
                <td>${worker.arl || 'Sin ARL'}</td>
                <td>${worker.eps || 'Sin EPS'}</td>
                <td><span class="status-badge ${statusClass}">${statusText}</span></td>
                <td>
                    <button class="btn btn-primary btn-sm" onclick="viewWorker('${worker.id}')">👁️</button>
                    <button class="btn btn-success btn-sm" onclick="editWorker('${worker.id}')">✏️</button>
                    <button class="btn btn-danger btn-sm" onclick="deleteWorker('${worker.id}')">🗑️</button>
                </td>
            `;
            tbody.appendChild(row);
        });

        // Update stats counter
        const totalWorkers = document.getElementById('totalWorkers');
        if (totalWorkers) totalWorkers.textContent = workersData.length;

    } catch (error) {
        console.error('Error workers:', error);
        tbody.innerHTML = '<tr><td colspan="8">Error cargando trabajadores.</td></tr>';
    }
}

async function renderInventoryTable() {
    const tbody = document.getElementById('inventarioTable');
    if (!tbody) return;
    tbody.innerHTML = '<tr><td colspan="8">Cargando inventario...</td></tr>';

    try {
        const response = await fetch('backend/api/inventory/read.php', { headers: getAuthHeaders() });

        if (response.status === 401) { window.location.href = 'pages/login.html'; return; }

        const data = await response.json();
        invList = Array.isArray(data) ? data : [];

        tbody.innerHTML = '';
        if (invList.length === 0) {
            tbody.innerHTML = '<tr><td colspan="8">Inventario vacío.</td></tr>';
            return;
        }

        invList.forEach(item => {
            const row = document.createElement('tr');
            const statusClass = item.status === 'DISPONIBLE' ? 'status-active' : (item.status === 'BAJO_STOCK' ? 'status-assigned' : 'status-inactive');
            
            // Resaltar stock bajo o crítico
            let stockClass = '';
            if (item.stock <= item.minStock) {
                stockClass = 'style="color: #ef4444; font-weight: bold;"';
            } else if (item.stock <= item.reorder) {
                stockClass = 'style="color: #f59e0b; font-weight: bold;"';
            }

            row.innerHTML = `
                <td>${item.id}</td>
                <td>${item.name}</td>
                <td>${item.category || 'N/A'}</td>
                <td>${item.brand || 'N/A'}</td>
                <td ${stockClass}>${item.stock}</td>
                <td>${item.minStock}</td>
                <td><span class="status-badge ${statusClass}">${item.status}</span></td>
                <td>
                    <button class="btn btn-success btn-sm" onclick="editInventory(${item.id})">✏️</button>
                    <button class="btn btn-danger btn-sm" onclick="deleteInventory(${item.id})">🗑️</button>
                </td>
            `;
            tbody.appendChild(row);
        });

        // Stats
        const totalEpp = document.getElementById('totalEpp');
        if (totalEpp) totalEpp.textContent = invList.filter(i => i.stock > 0).length;

    } catch (e) {
        console.error(e);
        tbody.innerHTML = '<tr><td colspan="8">Error cargando inventario.</td></tr>';
    }
}

async function renderRisksTable() {
    const tbody = document.getElementById('risksTable');
    if (!tbody) return;
    tbody.innerHTML = '<tr><td colspan="8">Cargando riesgos...</td></tr>';

    try {
        // Add timestamp to prevent caching
        const response = await fetch(`backend/api/risks/read.php?t=${new Date().getTime()}`, { headers: getAuthHeaders() });
        if (response.status === 401) { window.location.href = 'login.html'; return; }

        const data = await response.json();
        risks = Array.isArray(data) ? data : [];

        // Update Dashboard (Matrix & Stats)
        updateRiskDashboard(risks);

        tbody.innerHTML = '';
        if (risks.length === 0) {
            tbody.innerHTML = '<tr><td colspan="8">No hay riesgos registrados.</td></tr>';
            return;
        }

        risks.forEach(risk => {
            const row = document.createElement('tr');

            // Percentage fallback
            let percent = risk.percentage;
            // Normalize for fallback calc
            const pUpper = (risk.probability || '').trim().toUpperCase();
            const sUpper = (risk.severity || '').trim().toUpperCase();

            if (percent === undefined || percent === null) {
                const probVal = (pUpper === 'ALTA' ? 3 : (pUpper === 'MEDIA' ? 2 : 1));
                const sevVal = (sUpper === 'MUY GRAVE' ? 100 : (sUpper === 'GRAVE' ? 60 : (sUpper === 'MODERADA' ? 20 : 10)));
                percent = Math.round(((probVal * sevVal) / 300) * 100);
            }

            // Determine color
            let barColor = '#10b981'; // Green
            if (percent > 15) barColor = '#f59e0b'; // Yellow/Orange
            if (percent > 40) barColor = '#ef4444'; // Red

            row.innerHTML = `
                <td>${risk.id}</td>
                <td>${risk.name}</td>
                <td>${risk.type}</td>
                <td><span class="status-badge ${getRiskLevelClass(risk.level)}">${risk.level}</span></td>
                <td>
                    <div style="display: flex; align-items: center; gap: 8px;">
                        <div style="flex-grow: 1; background: #e5e7eb; height: 8px; border-radius: 4px; overflow: hidden;">
                            <div style="width: ${percent}%; background: ${barColor}; height: 100%;"></div>
                        </div>
                        <span style="font-size: 0.85em; width: 30px;">${percent}%</span>
                    </div>
                </td>
                <td>${risk.probability}</td>
                <td>${risk.severity}</td>
                <td>
                    <button class="btn btn-primary btn-sm" onclick="viewRisk(${risk.id})">👁️</button>
                    <button class="btn btn-success btn-sm" onclick="editRisk(${risk.id})">✏️</button>
                    <button class="btn btn-danger btn-sm" onclick="deleteRisk(${risk.id})">🗑️</button>
                </td>
            `;
            tbody.appendChild(row);
        });
    } catch (e) {
        console.error(e);
        tbody.innerHTML = '<tr><td colspan="8">Error al cargar riesgos.</td></tr>';
    }
}

// Helper for badge colors
function getRiskLevelClass(level) {
    switch (level) {
        case 'BAJO': return 'status-active'; // Greenish
        case 'MEDIO': return 'status-warning'; // Yellowish 
        case 'ALTO': return 'status-inactive'; // Reddish
        case 'MUY ALTO': return 'status-inactive'; // Reddish
        default: return '';
    }
}

// Auto-calculate risk level in form
function calculateRiskLevel() {
    const prob = document.getElementById('riskProb').value;
    const sev = document.getElementById('riskSev').value;
    const levelSelect = document.getElementById('riskLevel');

    let probVal = 1;
    if (prob === 'MEDIA') probVal = 2;
    if (prob === 'ALTA') probVal = 3;

    let sevVal = 10;
    if (sev === 'MODERADA') sevVal = 20;
    if (sev === 'GRAVE') sevVal = 60;
    if (sev === 'MUY GRAVE') sevVal = 100;

    const score = probVal * sevVal;

    let level = 'BAJO';
    if (score > 20) level = 'MEDIO';
    if (score > 50) level = 'ALTO';
    if (score > 150) level = 'MUY ALTO';

    levelSelect.value = level;
    // Optional: Visual indicator or lock
}

// Attach listeners
document.addEventListener('DOMContentLoaded', () => {
    const p = document.getElementById('riskProb');
    const s = document.getElementById('riskSev');
    if (p && s) {
        p.addEventListener('change', calculateRiskLevel);
        s.addEventListener('change', calculateRiskLevel);
    }
});

// -------------------------------------------------------------
// RISK DASHBOARD LOGIC (Matrix & Stats)
// -------------------------------------------------------------

function updateRiskDashboard(riskData) {
    // 1. Update Statistics Cards (Case insensitive filtering)
    const total = riskData.length;
    const high = riskData.filter(r => {
        const l = (r.level || '').toUpperCase();
        return l === 'ALTO' || l === 'MUY ALTO';
    }).length;
    const medium = riskData.filter(r => (r.level || '').toUpperCase() === 'MEDIO').length;
    const low = riskData.filter(r => (r.level || '').toUpperCase() === 'BAJO').length;

    if (document.getElementById('totalRisksCount')) document.getElementById('totalRisksCount').textContent = total;
    if (document.getElementById('highRisksCountStats')) document.getElementById('highRisksCountStats').textContent = high;
    if (document.getElementById('mediumRisksCountStats')) document.getElementById('mediumRisksCountStats').textContent = medium;
    if (document.getElementById('lowRisksCountStats')) document.getElementById('lowRisksCountStats').textContent = low;

    // Calculate Average Risk %
    let avgPercent = 0;
    if (total > 0) {
        const sumPercent = riskData.reduce((acc, curr) => {
            let p = curr.percentage;
            // Normalize for fallback calc
            const pUpper = (curr.probability || '').toUpperCase();
            const sUpper = (curr.severity || '').toUpperCase();

            if (p === undefined || p === null) {
                const probVal = (pUpper === 'ALTA' ? 3 : (pUpper === 'MEDIA' ? 2 : 1));
                const sevVal = (sUpper === 'MUY GRAVE' ? 100 : (sUpper === 'GRAVE' ? 60 : (sUpper === 'MODERADA' ? 20 : 10)));
                p = Math.round(((probVal * sevVal) / 300) * 100);
            }
            return acc + parseInt(p);
        }, 0);
        avgPercent = Math.round(sumPercent / total);
    }
    if (document.getElementById('avgRiskStats')) document.getElementById('avgRiskStats').textContent = avgPercent + '%';

    // 2. Update Matrix
    document.querySelectorAll('.matrix-cell').forEach(cell => {
        cell.innerHTML = '';
    });

    riskData.forEach(risk => {
        // Ensure values match ID format (e.g., MUY_GRAVE)
        let prob = (risk.probability || '').trim().toUpperCase();
        let sev = (risk.severity || '').trim().toUpperCase();

        // Normalize specific values
        sev = sev.replace(/\s+/g, '_'); // Replace spaces within the text with underscore

        const cellId = `cell-${prob}-${sev}`;
        const cell = document.getElementById(cellId);

        if (cell) {
            let countSpan = cell.querySelector('.matrix-count');
            if (!countSpan) {
                countSpan = document.createElement('span');
                countSpan.className = 'matrix-count';
                countSpan.textContent = 0;
                cell.appendChild(countSpan);
            }
            countSpan.textContent = parseInt(countSpan.textContent) + 1;
        }
    });
}

window.prepareAddRisk = function () {
    document.getElementById('addRiskForm').reset();
    document.getElementById('riskId').value = '';
    // Reset/Recalc level
    calculateRiskLevel();
    // Disable manual editing of level?
    document.getElementById('riskLevel').style.pointerEvents = 'none';
    document.getElementById('riskLevel').style.backgroundColor = '#f3f4f6';
    openModal('addRiskModal');
};

window.editRisk = function (id) {
    const risk = risks.find(r => r.id == id);
    if (!risk) return;

    document.getElementById('riskId').value = risk.id;
    document.getElementById('riskName').value = risk.name;
    document.getElementById('riskType').value = risk.type;
    document.getElementById('riskProb').value = risk.probability;
    document.getElementById('riskSev').value = risk.severity;

    // Auto-set level based on current prob/sev
    calculateRiskLevel();
    document.getElementById('riskLevel').style.pointerEvents = 'none';
    document.getElementById('riskLevel').style.backgroundColor = '#f3f4f6';

    document.getElementById('riskDesc').value = risk.description;
    document.getElementById('riskMeasures').value = risk.measures;

    openModal('addRiskModal');
};

// Save Risk (Create/Update)
document.getElementById('addRiskForm')?.addEventListener('submit', async function (e) {
    e.preventDefault();

    const submitBtn = this.querySelector('button[type="submit"]');
    const originalText = submitBtn.textContent;
    submitBtn.disabled = true;
    submitBtn.textContent = 'Guardando...';

    const id = document.getElementById('riskId').value;
    const isUpdate = id !== '';
    const url = isUpdate ? 'backend/api/risks/update.php' : 'backend/api/risks/create.php';

    const payload = {
        id: id ? parseInt(id) : null,
        name: document.getElementById('riskName').value,
        type: document.getElementById('riskType').value,
        level: document.getElementById('riskLevel').value,
        probability: document.getElementById('riskProb').value,
        severity: document.getElementById('riskSev').value,
        description: document.getElementById('riskDesc').value,
        measures: document.getElementById('riskMeasures').value
    };

    try {
        const res = await fetch(url, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(payload)
        });

        const data = await res.json();

        if (res.ok || res.status === 201) {
            alert(isUpdate ? 'Riesgo actualizado' : 'Riesgo guardado exitosamente');
            closeModal('addRiskModal');
            renderRisksTable(); // Will update matrix too
        } else {
            alert('Error: ' + (data.message || 'Error desconocido'));
        }
    } catch (e) {
        console.error('Error:', e);
        alert('Error de conexión');
    } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = originalText;
    }
});

window.deleteRisk = async function (id) {
    if (!confirm('¿Estás seguro de eliminar este riesgo?')) return;

    try {
        const res = await fetch('backend/api/risks/delete.php', {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify({ id })
        });

        if (res.ok) {
            alert('Riesgo eliminado');
            renderRisksTable();
        } else {
            alert('Error al eliminar');
        }
    } catch (e) {
        console.error(e);
        alert('Error de conexión');
    }
};

window.editRisk = function (id) {
    const risk = risks.find(r => r.id == id);
    if (!risk) return;

    document.getElementById('riskId').value = risk.id;
    document.getElementById('riskName').value = risk.name;
    document.getElementById('riskType').value = risk.type;
    document.getElementById('riskLevel').value = risk.level;
    document.getElementById('riskProb').value = risk.probability;
    document.getElementById('riskSev').value = risk.severity;
    document.getElementById('riskDesc').value = risk.description;
    document.getElementById('riskMeasures').value = risk.measures;

    openModal('addRiskModal');
};

// -------------------------------------------------------------
// HEALTH ENTITIES (ARL, EPS, IPS)
// -------------------------------------------------------------

async function renderHealthEntities() {
    const arlT = document.getElementById('arlTable');
    const epsT = document.getElementById('epsTable');
    const ipsT = document.getElementById('ipsTable');
    if (!arlT && !epsT && !ipsT) return;

    try {
        const [arlRes, epsRes, ipsRes] = await Promise.all([
            fetch('backend/api/arl/read.php', { headers: getAuthHeaders() }),
            fetch('backend/api/eps/read.php', { headers: getAuthHeaders() }),
            fetch('backend/api/ips/read.php', { headers: getAuthHeaders() })
        ]);

        if (arlRes.status === 401 || epsRes.status === 401 || ipsRes.status === 401) {
            window.location.href = 'pages/login.html';
            return;
        }

        const arlData = await arlRes.json();
        const epsData = await epsRes.json();
        const ipsData = await ipsRes.json();

        arlList = Array.isArray(arlData) ? arlData : [];
        epsList = Array.isArray(epsData) ? epsData : [];
        ipsList = Array.isArray(ipsData) ? ipsData : [];

        if (arlT) {
            arlT.innerHTML = arlList.length === 0 ? '<tr><td colspan="4">No hay ARL registradas.</td></tr>' : '';
            arlList.forEach(item => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${item.name}</td>
                    <td>${item.nit || '-'}</td>
                    <td>${item.phone}</td>
                    <td>
                        <button class="btn btn-primary btn-sm" onclick="editArl(${item.id})">✏️</button>
                        <button class="btn btn-danger btn-sm" onclick="deleteArl(${item.id})">🗑️</button>
                    </td>`;
                arlT.appendChild(row);
            });
        }

        if (epsT) {
            epsT.innerHTML = epsList.length === 0 ? '<tr><td colspan="4">No hay EPS registradas.</td></tr>' : '';
            epsList.forEach(item => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${item.name}</td>
                    <td>${item.address}</td>
                    <td>${item.phone}</td>
                    <td>
                        <button class="btn btn-primary btn-sm" onclick="editEps(${item.id})">✏️</button>
                        <button class="btn btn-danger btn-sm" onclick="deleteEps(${item.id})">🗑️</button>
                    </td>`;
                epsT.appendChild(row);
            });
        }

        if (ipsT) {
            ipsT.innerHTML = ipsList.length === 0 ? '<tr><td colspan="4">No hay IPS registradas.</td></tr>' : '';
            ipsList.forEach(item => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${item.name}</td>
                    <td>${item.address}</td>
                    <td>${item.phone}</td>
                    <td>
                        <button class="btn btn-primary btn-sm" onclick="editIps(${item.id})">✏️</button>
                        <button class="btn btn-danger btn-sm" onclick="deleteIps(${item.id})">🗑️</button>
                    </td>`;
                ipsT.appendChild(row);
            });
        }
    } catch (e) {
        console.error('Error health entities:', e);
        if (arlT) arlT.innerHTML = '<tr><td colspan="4">Error al cargar ARL.</td></tr>';
        if (epsT) epsT.innerHTML = '<tr><td colspan="4">Error al cargar EPS.</td></tr>';
        if (ipsT) ipsT.innerHTML = '<tr><td colspan="4">Error al cargar IPS.</td></tr>';
    }
}

window.prepareAddArl = function () {
    document.getElementById('arlForm').reset();
    document.getElementById('arlId').value = '';
    document.getElementById('arlModalTitle').textContent = 'Nueva ARL';
    openModal('arlModal');
};

window.editArl = function (id) {
    const item = arlList.find(i => i.id == id);
    if (!item) return;
    document.getElementById('arlId').value = item.id;
    document.getElementById('arlName').value = item.name;
    document.getElementById('arlNit').value = item.nit || '';
    document.getElementById('arlAddress').value = item.address || '';
    document.getElementById('arlPhone').value = item.phone || '';
    document.getElementById('arlEmail').value = item.email || '';
    document.getElementById('arlModalTitle').textContent = 'Editar ARL';
    openModal('arlModal');
};

async function saveArl() {
    const id = document.getElementById('arlId').value;
    const isUpdate = id !== '';
    const url = isUpdate ? 'backend/api/arl/update.php' : 'backend/api/arl/create.php';

    // Validaciones frontend coherentes con BD
    const name = document.getElementById('arlName').value.trim();
    const nit = document.getElementById('arlNit').value.trim();
    const address = document.getElementById('arlAddress').value.trim();
    const phone = document.getElementById('arlPhone').value.trim();
    const email = document.getElementById('arlEmail').value.trim();

    if (!name || name.length > 100) {
        alert('El nombre es obligatorio y no puede exceder 100 caracteres.');
        return;
    }

    // Validar NIT (BD: VARCHAR(20) UNIQUE) - formato: números y guiones
    if (!nit || !/^[\d-]+$/.test(nit) || nit.length > 20) {
        alert('El NIT es obligatorio, debe contener solo números y guiones (máximo 20 caracteres).');
        return;
    }

    if (!address || address.length > 200) {
        alert('La dirección es obligatoria y no puede exceder 200 caracteres.');
        return;
    }

    // Validar teléfono (BD: VARCHAR(15))
    if (!phone || !/^\d+$/.test(phone) || phone.length > 15 || phone.length < 7) {
        alert('El teléfono es obligatorio y debe contener solo números (7-15 dígitos).');
        return;
    }

    // Validar email si se proporciona (BD: VARCHAR(100))
    if (email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            alert('Debe ingresar un correo electrónico válido.');
            return;
        }
        if (email.length > 100) {
            alert('El correo no puede exceder 100 caracteres.');
            return;
        }
    }

    const payload = {
        id: id || undefined,
        name: name,
        nit: nit,
        address: address,
        phone: phone,
        email: email || null
    };
    if (isUpdate) payload.id = parseInt(id);

    try {
        const res = await fetch(url, { method: 'POST', headers: getAuthHeaders(), body: JSON.stringify(payload) });
        const data = await res.json().catch(() => ({}));
        if (res.ok) {
            alert(isUpdate ? 'ARL actualizada' : 'ARL creada exitosamente');
            closeModal('arlModal');
            renderHealthEntities();
        } else {
            alert('Error: ' + (data.message || 'Error desconocido'));
        }
    } catch (e) {
        console.error(e);
        alert('Error de conexión');
    }
}

window.deleteArl = async function (id) {
    if (!confirm('¿Eliminar esta ARL?')) return;
    try {
        const res = await fetch('backend/api/arl/delete.php', { method: 'POST', headers: getAuthHeaders(), body: JSON.stringify({ id }) });
        const data = await res.json().catch(() => ({}));
        if (res.ok) { alert('ARL eliminada'); renderHealthEntities(); } else alert('Error: ' + (data.message || 'Error'));
    } catch (e) { alert('Error de conexión'); }
};

window.prepareAddEps = function () {
    document.getElementById('epsForm').reset();
    document.getElementById('epsId').value = '';
    document.getElementById('epsModalTitle').textContent = 'Nueva EPS';
    openModal('epsModal');
};

window.editEps = function (id) {
    const item = epsList.find(i => i.id == id);
    if (!item) return;
    document.getElementById('epsId').value = item.id;
    document.getElementById('epsName').value = item.name;
    document.getElementById('epsAddress').value = item.address || '';
    document.getElementById('epsPhone').value = item.phone || '';
    document.getElementById('epsEmail').value = item.email || '';
    document.getElementById('epsModalTitle').textContent = 'Editar EPS';
    openModal('epsModal');
};

async function saveEps() {
    const id = document.getElementById('epsId').value;
    const isUpdate = id !== '';
    const url = isUpdate ? 'backend/api/eps/update.php' : 'backend/api/eps/create.php';

    // Validaciones frontend coherentes con BD
    const name = document.getElementById('epsName').value.trim();
    const address = document.getElementById('epsAddress').value.trim();
    const phone = document.getElementById('epsPhone').value.trim();
    const email = document.getElementById('epsEmail').value.trim();

    if (!name || name.length > 100) {
        alert('El nombre es obligatorio y no puede exceder 100 caracteres.');
        return;
    }

    if (!address || address.length > 200) {
        alert('La dirección es obligatoria y no puede exceder 200 caracteres.');
        return;
    }

    // Validar teléfono (BD: VARCHAR(15))
    if (!phone || !/^\d+$/.test(phone) || phone.length > 15 || phone.length < 7) {
        alert('El teléfono es obligatorio y debe contener solo números (7-15 dígitos).');
        return;
    }

    // Validar email si se proporciona (BD: VARCHAR(100))
    if (email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            alert('Debe ingresar un correo electrónico válido.');
            return;
        }
        if (email.length > 100) {
            alert('El correo no puede exceder 100 caracteres.');
            return;
        }
    }

    const payload = {
        name: name,
        address: address,
        phone: phone,
        email: email || null
    };
    if (isUpdate) payload.id = parseInt(id);

    try {
        const res = await fetch(url, { method: 'POST', headers: getAuthHeaders(), body: JSON.stringify(payload) });
        const data = await res.json().catch(() => ({}));
        if (res.ok) {
            alert(isUpdate ? 'EPS actualizada' : 'EPS creada exitosamente');
            closeModal('epsModal');
            renderHealthEntities();
        } else {
            alert('Error: ' + (data.message || 'Error desconocido'));
        }
    } catch (e) {
        console.error(e);
        alert('Error de conexión');
    }
}

window.deleteEps = async function (id) {
    if (!confirm('¿Eliminar esta EPS?')) return;
    try {
        const res = await fetch('backend/api/eps/delete.php', { method: 'POST', headers: getAuthHeaders(), body: JSON.stringify({ id }) });
        const data = await res.json().catch(() => ({}));
        if (res.ok) { alert('EPS eliminada'); renderHealthEntities(); } else alert('Error: ' + (data.message || 'Error'));
    } catch (e) { alert('Error de conexión'); }
};

window.prepareAddIps = function () {
    document.getElementById('ipsForm').reset();
    document.getElementById('ipsId').value = '';
    document.getElementById('ipsModalTitle').textContent = 'Nueva IPS';
    openModal('ipsModal');
};

window.editIps = function (id) {
    const item = ipsList.find(i => i.id == id);
    if (!item) return;
    document.getElementById('ipsId').value = item.id;
    document.getElementById('ipsName').value = item.name;
    document.getElementById('ipsAddress').value = item.address || '';
    document.getElementById('ipsPhone').value = item.phone || '';
    document.getElementById('ipsEmail').value = item.email || '';
    document.getElementById('ipsModalTitle').textContent = 'Editar IPS';
    openModal('ipsModal');
};

async function saveIps() {
    const id = document.getElementById('ipsId').value;
    const isUpdate = id !== '';
    const url = isUpdate ? 'backend/api/ips/update.php' : 'backend/api/ips/create.php';

    // Validaciones frontend coherentes con BD
    const name = document.getElementById('ipsName').value.trim();
    const address = document.getElementById('ipsAddress').value.trim();
    const phone = document.getElementById('ipsPhone').value.trim();
    const email = document.getElementById('ipsEmail').value.trim();

    if (!name || name.length > 100) {
        alert('El nombre es obligatorio y no puede exceder 100 caracteres.');
        return;
    }

    if (!address || address.length > 200) {
        alert('La dirección es obligatoria y no puede exceder 200 caracteres.');
        return;
    }

    // Validar teléfono (BD: VARCHAR(15))
    if (!phone || !/^\d+$/.test(phone) || phone.length > 15 || phone.length < 7) {
        alert('El teléfono es obligatorio y debe contener solo números (7-15 dígitos).');
        return;
    }

    // Validar email si se proporciona (BD: VARCHAR(100))
    if (email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            alert('Debe ingresar un correo electrónico válido.');
            return;
        }
        if (email.length > 100) {
            alert('El correo no puede exceder 100 caracteres.');
            return;
        }
    }

    const payload = {
        name: name,
        address: address,
        phone: phone,
        email: email || null
    };
    if (isUpdate) payload.id = parseInt(id);

    try {
        const res = await fetch(url, { method: 'POST', headers: getAuthHeaders(), body: JSON.stringify(payload) });
        const data = await res.json().catch(() => ({}));
        if (res.ok) {
            alert(isUpdate ? 'IPS actualizada' : 'IPS creada exitosamente');
            closeModal('ipsModal');
            renderHealthEntities();
        } else {
            alert('Error: ' + (data.message || 'Error desconocido'));
        }
    } catch (e) {
        console.error(e);
        alert('Error de conexión');
    }
}

window.deleteIps = async function (id) {
    if (!confirm('¿Eliminar esta IPS?')) return;
    try {
        const res = await fetch('backend/api/ips/delete.php', { method: 'POST', headers: getAuthHeaders(), body: JSON.stringify({ id }) });
        const data = await res.json().catch(() => ({}));
        if (res.ok) { alert('IPS eliminada'); renderHealthEntities(); } else alert('Error: ' + (data.message || 'Error'));
    } catch (e) { alert('Error de conexión'); }
};

// -------------------------------------------------------------
// ADD FUNCTIONS (API)
// -------------------------------------------------------------

async function addNewUser() {
    const name = document.getElementById('userNameInput').value;
    const lastName = document.getElementById('userLastNameInput').value;
    const email = document.getElementById('userEmailInput').value;
    const password = document.getElementById('userPasswordInput').value;
    const confirmPassword = document.getElementById('userPasswordConfirm').value;
    const role = document.getElementById('userRoleSelect').value;
    const status = document.getElementById('userStatusSelect').value;

    if (password !== confirmPassword) {
        alert('Las contraseñas no coinciden');
        return;
    }

    const newUser = {
        name: name,
        lastName: lastName,
        email: email,
        password: password,
        role: role, // 1 or 2
        status: status
    };

    try {
        const response = await fetch('backend/api/users/create.php', {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(newUser)
        });

        if (response.ok) {
            alert('Usuario creado exitosamente');
            closeModal('addUserModal');
            document.getElementById('addUserForm').reset();
            renderUsersTable();
        } else {
            const err = await response.json();
            alert('Error: ' + err.message);
        }
    } catch (e) {
        console.error(e);
        alert('Error de conexión');
    }
}

async function addNewWorker() {
    const docType = document.getElementById('docType').value;
    const docNumber = document.getElementById('docNumber').value;
    const name = document.getElementById('workerName').value;
    const lastName = document.getElementById('workerLastName').value;
    const positionId = document.getElementById('workerPosition').value;
    const startDate = document.getElementById('workerStartDate').value;
    const phone = document.getElementById('workerPhone').value;
    const email = document.getElementById('workerEmail').value;
    const address = document.getElementById('workerAddress') ? document.getElementById('workerAddress').value : '';
    const rh = document.getElementById('workerRh') ? document.getElementById('workerRh').value : '';
    const sex = document.getElementById('workerSex') ? document.getElementById('workerSex').value : '';

    const newWorker = {
        id: docNumber,
        doc_type: docType,
        name: name,
        lastName: lastName,
        position_id: positionId,
        startDate: startDate,
        phone: phone,
        email: email,
        address: address,
        rh: rh,
        sex: sex
    };

    try {
        const response = await fetch('backend/api/workers/create.php', {
            method: 'POST',
            headers: getAuthHeaders(),
            credentials: 'include',
            body: JSON.stringify(newWorker)
        });

        if (response.ok) {
            alert('Trabajador agregado exitosamente');
            closeModal('addWorkerModal');
            location.reload();
        } else {
            const errorData = await response.json();
            alert('Error al crear trabajador: ' + (errorData.message || 'Error desconocido'));
        }
    } catch (error) {
        console.error('Error:', error);
        alert('Error de conexión al crear trabajador');
    }
}


// -------------------------------------------------------------------------
// EPP CRUD
// -------------------------------------------------------------------------

async function loadBrandsAndCategories() {
    try {
        // Load Brands
        const brandRes = await fetch('backend/api/brands/read.php', { headers: getAuthHeaders() });
        const brands = await brandRes.json();
        const brandSelect = document.getElementById('eppBrand');
        brandSelect.innerHTML = '<option value="">Seleccione Marca</option>';
        if (Array.isArray(brands)) {
            brands.forEach(b => {
                brandSelect.innerHTML += `<option value="${b.id}">${b.name}</option>`;
            });
        }

        // Load Categories
        const catRes = await fetch('backend/api/categories/read.php', { headers: getAuthHeaders() });
        const cats = await catRes.json();
        const catSelect = document.getElementById('eppCategory');
        catSelect.innerHTML = '<option value="">Seleccione Categoría</option>';
        if (Array.isArray(cats)) {
            cats.forEach(c => {
                catSelect.innerHTML += `<option value="${c.id}">${c.name}</option>`;
            });
        }
    } catch (e) {
        console.error('Error loading selects', e);
    }
}

window.prepareAddEpp = async function () {
    document.getElementById('addEquipmentForm').reset();
    document.getElementById('eppId').value = '';
    await loadBrandsAndCategories();
    openModal('addEquipmentModal');
};

async function saveEpp() {
    const id = document.getElementById('eppId').value;
    const isUpdate = id !== '';
    const url = isUpdate ? 'backend/api/epp/update.php' : 'backend/api/epp/create.php';

    const brandVal = document.getElementById('eppBrand').value;
    const catVal = document.getElementById('eppCategory').value;
    if (!brandVal || !catVal) {
        alert('Debe seleccionar Marca y Categoría.');
        return;
    }

    // Validaciones adicionales de front antes de enviar al backend
    const name = document.getElementById('eppName').value.trim();
    const type = document.getElementById('eppType').value.trim();
    const size = document.getElementById('eppSize').value.trim();
    const reference = document.getElementById('eppReference').value.trim();
    const manufacturer = document.getElementById('eppManufacturer').value.trim();
    const serial = document.getElementById('eppSerial').value.trim();
    const fabDate = document.getElementById('eppFabDate').value;
    const expDate = document.getElementById('eppExpDate').value;
    const buyDate = document.getElementById('eppBuyDate').value;
    const lifeMonthsRaw = document.getElementById('eppLife').value;
    const description = document.getElementById('eppDescription').value.trim();

    if (!name || !type || !size || !reference || !manufacturer || !serial || !fabDate || !expDate || !buyDate || !lifeMonthsRaw || !description) {
        alert('Todos los campos del EPP son obligatorios.');
        return;
    }

    const lifeMonths = parseInt(lifeMonthsRaw, 10);
    if (isNaN(lifeMonths) || lifeMonths <= 0) {
        alert('La vida útil (meses) debe ser un número mayor que 0.');
        return;
    }

    const fab = new Date(fabDate);
    const buy = new Date(buyDate);
    const exp = new Date(expDate);
    if (fab > buy) {
        alert('La fecha de compra no puede ser anterior a la fecha de fabricación.');
        return;
    }
    if (buy > exp) {
        alert('La fecha de vencimiento debe ser posterior a la fecha de compra.');
        return;
    }
    if (fab > exp) {
        alert('La fecha de vencimiento debe ser posterior a la fecha de fabricación.');
        return;
    }

    const eppData = {
        id: id,
        name: name,
        type: type,
        brand_id: brandVal,
        category_id: catVal,
        size: size,
        reference: reference,
        manufacturer: manufacturer,
        serial: serial,
        fab_date: fabDate,
        exp_date: expDate,
        buy_date: buyDate,
        life_months: lifeMonths,
        description: description
    };

    try {
        const response = await fetch(url, getFetchOpts('POST', eppData));
        const data = await response.json().catch(() => ({}));

        if (response.ok) {
            alert(isUpdate ? 'EPP actualizado exitosamente' : 'EPP creado exitosamente');
            closeModal('addEquipmentModal');
            document.getElementById('addEquipmentForm').reset();
            renderEppTable();
            // Muy importante: Si creamos un EPP, el backend crea un registro en inventario
            if (document.getElementById('inventarioTable')) renderInventoryTable();
            if (document.getElementById('totalWorkers')) loadDashboardStats();
        } else {
            if (data.missing_fields) {
                alert('Faltan datos obligatorios: ' + data.missing_fields.join(', '));
            } else {
                alert('Error: ' + (data.message || 'Error desconocido del servidor'));
            }
        }
    } catch (e) {
        console.error('saveEpp error:', e);
        alert('Error de conexión con el servidor: ' + e.message);
    }
}

window.editEpp = async function (id) {
    const item = eppList.find(i => i.id == id);
    if (!item) return;

    await loadBrandsAndCategories();

    document.getElementById('eppId').value = item.id;
    document.getElementById('eppName').value = item.name;
    document.getElementById('eppType').value = item.type;
    document.getElementById('eppBrand').value = item.brand_id;
    document.getElementById('eppCategory').value = item.category_id;
    document.getElementById('eppSize').value = item.size;
    document.getElementById('eppReference').value = item.reference;
    document.getElementById('eppManufacturer').value = item.manufacturer;
    document.getElementById('eppSerial').value = item.serial;
    document.getElementById('eppFabDate').value = item.fab_date;
    document.getElementById('eppExpDate').value = item.exp_date;
    document.getElementById('eppBuyDate').value = item.buy_date;
    document.getElementById('eppLife').value = item.life_months;
    document.getElementById('eppDescription').value = item.description;

    openModal('addEquipmentModal');
};

window.deleteEpp = async function (id) {
    if (!confirm('¿Está seguro de eliminar este EPP?')) return;

    try {
        const response = await fetch('backend/api/epp/delete.php', {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify({ id: id })
        });

        if (response.ok) {
            alert('EPP eliminado');
            renderEppTable();
        } else {
            const err = await response.json();
            alert('Error: ' + err.message);
        }
    } catch (e) {
        console.error(e);
        alert('Error de conexión');
    }
};

// -------------------------------------------------------------------------
// INVENTORY CRUD
// -------------------------------------------------------------------------

window.prepareAddInventory = async function () {
    document.getElementById('addEppForm').reset();
    document.getElementById('invId').value = '';
    document.getElementById('invEppId').disabled = false;
    await loadEppForInventory();
    openModal('addEppModal');
};

async function loadEppForInventory() {
    const sel = document.getElementById('invEppId');
    if (!sel) return;
    try {
        const res = await fetch('backend/api/epp/read.php', { headers: getAuthHeaders() });
        const epps = await res.json();
        sel.innerHTML = '<option value="">Seleccione EPP</option>';
        if (Array.isArray(epps)) {
            epps.forEach(e => { sel.innerHTML += `<option value="${e.id}">${e.name} - ${e.reference || ''}</option>`; });
        }
    } catch (e) { console.error('Error EPP:', e); sel.innerHTML = '<option value="">Error al cargar</option>'; }
}

async function saveInventory() {
    const id = document.getElementById('invId').value;
    const isUpdate = id !== '';
    const url = isUpdate ? 'backend/api/inventory/update.php' : 'backend/api/inventory/create.php';

    const eppId = document.getElementById('invEppId').value;
    const stockRaw = document.getElementById('invStock').value;
    const minRaw = document.getElementById('invMinStock').value;
    const maxRaw = document.getElementById('invMaxStock').value;
    const reorderRaw = document.getElementById('invReorder').value;

    if (!eppId) {
        alert('Debe seleccionar un EPP para el inventario.');
        return;
    }

    const stock = parseInt(stockRaw, 10);
    const minStock = parseInt(minRaw, 10);
    const maxStock = parseInt(maxRaw, 10);
    const reorder = parseInt(reorderRaw, 10);

    if ([stock, minStock, maxStock, reorder].some(v => isNaN(v))) {
        alert('Stock, punto de reorden, mínimo y máximo deben ser números válidos.');
        return;
    }
    if (stock < 0) {
        alert('El stock actual no puede ser negativo.');
        return;
    }
    if (maxStock <= minStock) {
        alert('El stock máximo debe ser mayor que el stock mínimo.');
        return;
    }
    if (reorder < minStock || reorder > maxStock) {
        alert('El punto de reorden debe estar entre el stock mínimo y el máximo.');
        return;
    }

    const invData = {
        id: id,
        epp_id: eppId,
        stock: stock,
        min_stock: minStock,
        max_stock: maxStock,
        reorder_point: reorder
    };

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(invData)
        });

        const data = await response.json().catch(() => ({}));

        if (response.ok) {
            alert(isUpdate ? 'Inventario actualizado exitosamente' : 'Inventario procesado exitosamente');
            closeModal('addEppModal');
            document.getElementById('addEppForm').reset();
            renderInventoryTable();
            // Si hay un dashboard, también actualizarlo
            if (document.getElementById('totalWorkers')) loadDashboardStats();
        } else {
            alert('Error: ' + (data.message || 'Error desconocido'));
        }
    } catch (e) {
        console.error(e);
        alert('Error de conexión con el servidor');
    }
}

window.editInventory = async function (id) {
    const item = invList.find(i => i.id == id);
    if (!item) return;

    await loadEppForInventory();

    document.getElementById('invId').value = item.id;
    document.getElementById('invEppId').value = item.epp_id;
    document.getElementById('invEppId').disabled = true;

    document.getElementById('invStock').value = item.stock;
    document.getElementById('invMinStock').value = item.minStock;
    document.getElementById('invMaxStock').value = item.maxStock;
    document.getElementById('invReorder').value = item.reorder;

    openModal('addEppModal');
};

window.deleteInventory = async function (id) {
    if (!confirm('¿Está seguro de eliminar este item de inventario?')) return;

    try {
        const response = await fetch('backend/api/inventory/delete.php', {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify({ id: id })
        });

        if (response.ok) {
            alert('Item eliminado');
            renderInventoryTable();
        } else {
            const err = await response.json();
            alert('Error: ' + err.message);
        }
    } catch (e) {
        console.error(e);
        alert('Error de conexión');
    }
};

// -------------------------------------------------------------------------
// USERS CRUD
// -------------------------------------------------------------------------

window.prepareAddUser = function () {
    document.getElementById('addUserForm').reset();
    document.getElementById('userId').value = '';
    openModal('addUserModal');
};

async function saveUser() {
    const id = document.getElementById('userId').value;
    const isUpdate = id !== '';
    const url = isUpdate ? 'backend/api/users/update.php' : 'backend/api/users/create.php';

    const name = document.getElementById('userNameInput').value.trim();
    const lastName = document.getElementById('userLastNameInput').value.trim();
    const email = document.getElementById('userEmailInput').value.trim();
    const password = document.getElementById('userPasswordInput').value;
    const confirmPassword = document.getElementById('userPasswordConfirm').value;
    const role = document.getElementById('userRoleSelect').value;
    const status = document.getElementById('userStatusSelect').value;

    // Validaciones frontend coherentes con BD
    if (!name || name.length > 100) {
        alert('El nombre es obligatorio y no puede exceder 100 caracteres.');
        return;
    }
    if (!lastName || lastName.length > 100) {
        alert('El apellido es obligatorio y no puede exceder 100 caracteres.');
        return;
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!email || !emailRegex.test(email)) {
        alert('Debe ingresar un correo electrónico válido.');
        return;
    }
    if (email.length > 150) {
        alert('El correo no puede exceder 150 caracteres.');
        return;
    }

    if (!isUpdate && !password) {
        alert('La contraseña es obligatoria para nuevos usuarios');
        return;
    }

    if (password) {
        if (password.length < 8) {
            alert('La contraseña debe tener al menos 8 caracteres.');
            return;
        }
        if (!/[A-Z]/.test(password) || !/[0-9]/.test(password)) {
            alert('La contraseña debe contener al menos una mayúscula y un número.');
            return;
        }
        if (password !== confirmPassword) {
            alert('Las contraseñas no coinciden');
            return;
        }
    }

    if (!['1', '2'].includes(role)) {
        alert('Debe seleccionar un rol válido.');
        return;
    }

    if (!['ACTIVO', 'INACTIVO'].includes(status)) {
        alert('Debe seleccionar un estado válido.');
        return;
    }

    const userData = {
        id: id,
        name: name,
        lastName: lastName,
        email: email,
        role: role,
        status: status
    };

    if (password) {
        userData.password = password;
    }

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(userData)
        });

        if (response.ok) {
            alert(isUpdate ? 'Usuario actualizado exitosamente' : 'Usuario creado exitosamente');
            closeModal('addUserModal');
            document.getElementById('addUserForm').reset();
            renderUsersTable();
        } else {
            const err = await response.json();
            alert('Error: ' + err.message);
        }
    } catch (e) {
        console.error(e);
        alert('Error de conexión');
    }
}

// Replace old addNewUser with saveUser hook
window.addNewUser = saveUser;

const addUserForm = document.getElementById('addUserForm');
if (addUserForm) {
    addUserForm.addEventListener('submit', function (e) {
        e.preventDefault();
        saveUser();
    });
}

window.editUser = function (userId) {
    const user = usersList.find(u => u.id == userId);
    if (!user) return;

    document.getElementById('userId').value = user.id;
    document.getElementById('userNameInput').value = user.name; // Now just first name
    document.getElementById('userLastNameInput').value = user.lastName;
    document.getElementById('userEmailInput').value = user.email;
    document.getElementById('userRoleSelect').value = user.role_id || (user.role === 'ADMINISTRADOR' ? '1' : '2');
    document.getElementById('userStatusSelect').value = user.status;
    document.getElementById('userPasswordInput').value = '';
    document.getElementById('userPasswordConfirm').value = '';

    openModal('addUserModal');
};

async function deleteUser(userId) {
    if (confirm('¿Está seguro de eliminar este usuario?')) {
        try {
            const response = await fetch('backend/api/users/delete.php', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${localStorage.getItem('token')}`
                },
                body: JSON.stringify({ id: userId })
            });

            if (response.ok) {
                alert('Usuario eliminado exitosamente');
                renderUsersTable(); // Reload table from DB
            } else {
                const err = await response.json();
                alert('Error al eliminar: ' + (err.message || 'Error desconocido'));
            }
        } catch (e) {
            console.error(e);
            alert('Error de conexión al intentar eliminar el usuario');
        }
    }
}

// -------------------------------------------------------------------------
// WORKERS CRUD
// -------------------------------------------------------------------------

window.prepareAddWorker = async function () {
    document.getElementById('addWorkerForm').reset();
    document.getElementById('workerId').value = '';
    document.getElementById('docNumber').disabled = false;
    await loadWorkerSelects();
    openModal('addWorkerModal');
};

async function loadWorkerSelects() {
    try {
        const [cargosRes, arlRes, epsRes] = await Promise.all([
            fetch('backend/api/cargos/read.php', { headers: getAuthHeaders(), credentials: 'include' }),
            fetch('backend/api/arl/read.php', { headers: getAuthHeaders(), credentials: 'include' }),
            fetch('backend/api/eps/read.php', { headers: getAuthHeaders(), credentials: 'include' })
        ]);
        const cargos = await cargosRes.json();
        const arls = await arlRes.json();
        const epss = await epsRes.json();

        const posSel = document.getElementById('workerPosition');
        if (posSel) {
            posSel.innerHTML = '<option value="">Seleccione Cargo</option>';
            if (Array.isArray(cargos)) cargos.forEach(c => { posSel.innerHTML += `<option value="${c.id}">${c.name}</option>`; });
        }
        const arlSel = document.getElementById('workerArl');
        if (arlSel) {
            arlSel.innerHTML = '<option value="">Seleccione ARL</option>';
            if (Array.isArray(arls)) arls.forEach(a => { arlSel.innerHTML += `<option value="${a.id}">${a.name}</option>`; });
        }
        const epsSel = document.getElementById('workerEps');
        if (epsSel) {
            epsSel.innerHTML = '<option value="">Seleccione EPS</option>';
            if (Array.isArray(epss)) epss.forEach(e => { epsSel.innerHTML += `<option value="${e.id}">${e.name}</option>`; });
        }
    } catch (e) { console.error('Error carga selects:', e); }
}

async function saveWorker() {
    const id = document.getElementById('workerId').value;
    const docNumber = document.getElementById('docNumber').value.trim();
    const dbId = id || docNumber;
    const isUpdate = id !== '';
    const url = isUpdate ? 'backend/api/workers/update.php' : 'backend/api/workers/create.php';

    // Validaciones frontend coherentes con BD
    const docType = document.getElementById('docType').value;
    if (!docNumber) {
        alert('El número de documento es obligatorio.');
        return;
    }
    // Validar formato de documento según tipo (BD: VARCHAR(20))
    if (docNumber.length > 20) {
        alert('El número de documento no puede exceder 20 caracteres.');
        return;
    }
    // Para CC, CE, TI: solo dígitos; para NIT: dígitos y guiones; PAS: alfanumérico
    if (['CC', 'CE', 'TI'].includes(docType) && !/^\d+$/.test(docNumber)) {
        alert(`Para ${docType === 'CC' ? 'Cédula' : docType === 'CE' ? 'Cédula de Extranjería' : 'Tarjeta de Identidad'}, el documento debe contener solo números.`);
        return;
    }
    if (docType === 'NIT' && !/^[\d-]+$/.test(docNumber)) {
        alert('El NIT debe contener solo números y guiones.');
        return;
    }

    const name = document.getElementById('workerName').value.trim();
    const lastName = document.getElementById('workerLastName').value.trim();
    if (!name || name.length > 100) {
        alert('El nombre es obligatorio y no puede exceder 100 caracteres.');
        return;
    }
    if (!lastName || lastName.length > 100) {
        alert('El apellido es obligatorio y no puede exceder 100 caracteres.');
        return;
    }

    const email = document.getElementById('workerEmail').value.trim();
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!email || !emailRegex.test(email)) {
        alert('Debe ingresar un correo electrónico válido.');
        return;
    }
    if (email.length > 100) {
        alert('El correo no puede exceder 100 caracteres.');
        return;
    }

    const phone = document.getElementById('workerPhone').value.trim();
    // BD: VARCHAR(15), validar solo dígitos y longitud
    if (!phone || !/^\d+$/.test(phone)) {
        alert('El teléfono debe contener solo números.');
        return;
    }
    if (phone.length > 15 || phone.length < 7) {
        alert('El teléfono debe tener entre 7 y 15 dígitos.');
        return;
    }

    const address = document.getElementById('workerAddress') ? document.getElementById('workerAddress').value.trim() : '';
    if (!address || address.length > 200) {
        alert('La dirección es obligatoria y no puede exceder 200 caracteres.');
        return;
    }

    const startDate = document.getElementById('workerStartDate').value;
    if (!startDate) {
        alert('La fecha de ingreso es obligatoria.');
        return;
    }
    const startDateObj = new Date(startDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    if (startDateObj > today) {
        alert('La fecha de ingreso no puede ser mayor a la fecha actual.');
        return;
    }

    const positionId = document.getElementById('workerPosition').value;
    if (!positionId) {
        alert('Debe seleccionar un cargo.');
        return;
    }

    const rh = document.getElementById('workerRh') ? document.getElementById('workerRh').value : 'O+';
    if (!rh || !['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'].includes(rh)) {
        alert('Debe seleccionar un tipo sanguíneo válido.');
        return;
    }

    const sex = document.getElementById('workerSex') ? document.getElementById('workerSex').value : 'MASCULINO';
    if (!sex || !['MASCULINO', 'FEMENINO', 'OTRO'].includes(sex)) {
        alert('Debe seleccionar un sexo válido.');
        return;
    }

    const workerData = {
        id: dbId,
        doc_type: docType,
        name: name,
        lastName: lastName,
        position_id: positionId,
        startDate: startDate,
        phone: phone,
        email: email,
        address: address,
        rh: rh,
        sex: sex,
        arl_id: document.getElementById('workerArl') ? document.getElementById('workerArl').value : '',
        eps_id: document.getElementById('workerEps') ? document.getElementById('workerEps').value : ''
    };

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: getAuthHeaders(),
            credentials: 'include',
            body: JSON.stringify(workerData)
        });

        if (response.ok) {
            alert(isUpdate ? 'Trabajador actualizado' : 'Trabajador creado');
            closeModal('addWorkerModal');
            location.reload();
        } else {
            const err = await response.json();
            alert('Error: ' + err.message);
        }
    } catch (e) {
        console.error(e);
        alert('Error de conexión');
    }
}

// Replace old addNewWorker
window.addNewWorker = saveWorker;

const addWorkerForm = document.getElementById('addWorkerForm');
if (addWorkerForm) {
    addWorkerForm.addEventListener('submit', function (e) {
        e.preventDefault();
        saveWorker();
    });
}

window.editWorker = async function (workerId) {
    const worker = workers.find(w => w.id == workerId);
    if (!worker) return;

    await loadWorkerSelects();

    document.getElementById('workerId').value = worker.id;
    document.getElementById('docType').value = worker.doc_type || 'CC';
    document.getElementById('docNumber').value = worker.id;
    document.getElementById('docNumber').disabled = true;
    document.getElementById('workerName').value = worker.name;
    document.getElementById('workerLastName').value = worker.lastName;
    document.getElementById('workerPosition').value = worker.position_id || '1';
    document.getElementById('workerStartDate').value = worker.startDate;
    document.getElementById('workerPhone').value = worker.phone || '';
    document.getElementById('workerEmail').value = worker.email || '';
    const addrEl = document.getElementById('workerAddress');
    const rhEl = document.getElementById('workerRh');
    const sexEl = document.getElementById('workerSex');
    if (addrEl) addrEl.value = worker.address || '';
    if (rhEl) rhEl.value = worker.rh || '';
    if (sexEl) sexEl.value = worker.sex || '';
    const arlEl = document.getElementById('workerArl');
    const epsEl = document.getElementById('workerEps');
    if (arlEl && worker.arl_id) arlEl.value = worker.arl_id;
    if (epsEl && worker.eps_id) epsEl.value = worker.eps_id;

    openModal('addWorkerModal');
};

function viewWorker(workerId) {
    const worker = workers.find(w => w.id === workerId);
    if (worker) alert(`Ver trabajador: ${worker.name} ${worker.lastName}\nCargo: ${worker.position}\nARL: ${worker.arl}\nEPS: ${worker.eps}`);
}

async function deleteWorker(workerId) {
    if (!confirm('¿Está seguro de eliminar este trabajador?')) return;

    try {
        const response = await fetch('backend/api/workers/delete.php', {
            method: 'POST',
            headers: getAuthHeaders(),
            credentials: 'include',
            body: JSON.stringify({ id: workerId })
        });

        if (response.ok) {
            alert('Trabajador eliminado');
            location.reload();
        } else {
            const err = await response.json();
            alert('Error: ' + err.message);
        }
    } catch (e) {
        console.error(e);
        alert('Error de conexión');
    }
}


function viewRisk(riskId) {
    const risk = risks.find(r => r.id === riskId);
    if (risk) alert(`Ver riesgo: ${risk.name}\nTipo: ${risk.type}\nNivel: ${risk.level}\nProbabilidad: ${risk.probability}`);
}

// -------------------------------------------------------------------------
// RISKS CRUD
// -------------------------------------------------------------------------

window.prepareAddRisk = function () {
    document.getElementById('addRiskForm').reset();
    document.getElementById('riskId').value = '';
    openModal('addRiskModal');
};

async function saveRisk() {
    const id = document.getElementById('riskId').value;
    const isUpdate = id !== '';
    const url = isUpdate ? 'backend/api/risks/update.php' : 'backend/api/risks/create.php';

    const riskData = {
        id: id,
        name: document.getElementById('riskName').value,
        type: document.getElementById('riskType').value,
        level: document.getElementById('riskLevel').value,
        probability: document.getElementById('riskProb').value,
        severity: document.getElementById('riskSev').value,
        description: document.getElementById('riskDesc').value,
        measures: document.getElementById('riskMeasures').value
    };

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(riskData)
        });

        if (response.ok) {
            alert(isUpdate ? 'Riesgo actualizado' : 'Riesgo creado');
            closeModal('addRiskModal');
            renderRisksTable();
        } else {
            const err = await response.json();
            alert('Error: ' + err.message);
        }
    } catch (e) {
        console.error(e);
        alert('Error de conexión');
    }
}

const addRiskForm = document.getElementById('addRiskForm');
if (addRiskForm) {
    addRiskForm.addEventListener('submit', function (e) {
        e.preventDefault();
        saveRisk();
    });
}

window.editRisk = function (riskId) {
    // Need to find risk in local list or fetch it
    // Since renderRisksTable doesn't store in global 'risks' well (it does but let's ensure)
    // We will trust the global 'risks' variable populated in renderRisksTable
    const risk = risks.find(r => r.id == riskId); // loose equality for string/int
    if (!risk) return;

    document.getElementById('riskId').value = risk.id;
    document.getElementById('riskName').value = risk.name;
    document.getElementById('riskType').value = risk.type;
    document.getElementById('riskLevel').value = risk.level;
    document.getElementById('riskProb').value = risk.probability;
    document.getElementById('riskSev').value = risk.severity;
    document.getElementById('riskDesc').value = risk.description || '';
    document.getElementById('riskMeasures').value = risk.measures || '';

    openModal('addRiskModal');
};

window.deleteRisk = async function (riskId) {
    if (!confirm('¿Está seguro de eliminar este riesgo?')) return;

    try {
        const response = await fetch('backend/api/risks/delete.php', {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify({ id: riskId })
        });

        if (response.ok) {
            alert('Riesgo eliminado');
            renderRisksTable();
        } else {
            const err = await response.json();
            alert('Error: ' + err.message);
        }
    } catch (e) {
        console.error(e);
        alert('Error de conexión');
    }
};


async function generateReport(type) {
    // Cargar datos si no están disponibles
    if (type === 'workers' && (!workers || workers.length === 0)) {
        await renderWorkersTable();
    }
    if (type === 'inventory' && (!invList || invList.length === 0)) {
        await renderInventoryTable();
    }
    if (type === 'risks' && (!risks || risks.length === 0)) {
        await renderRisksTable();
    }

    let reportContent = '';
    let reportTitle = '';

    switch (type) {
        case 'workers':
            reportTitle = 'REPORTE DE TRABAJADORES';
            reportContent = `${reportTitle}\nFecha: ${new Date().toLocaleDateString('es-ES')}\n\n`;
            if (workers && workers.length > 0) {
                workers.forEach(w => {
                    reportContent += `${w.id} - ${w.name} ${w.lastName} - ${w.position || 'Sin cargo'} - ${w.startDate || 'Sin fecha'}\n`;
                });
            } else {
                reportContent += 'No hay trabajadores registrados.\n';
            }
            break;
        case 'inventory':
            reportTitle = 'REPORTE DE INVENTARIO EPP';
            reportContent = `${reportTitle}\nFecha: ${new Date().toLocaleDateString('es-ES')}\n\n`;
            if (invList && invList.length > 0) {
                invList.forEach(i => {
                    reportContent += `${i.id} - ${i.name} - Stock: ${i.stock} - Mín: ${i.minStock} - Máx: ${i.maxStock} - Estado: ${i.status}\n`;
                });
            } else {
                reportContent += 'No hay inventario registrado.\n';
            }
            break;
        case 'risks':
            reportTitle = 'REPORTE DE RIESGOS';
            reportContent = `${reportTitle}\nFecha: ${new Date().toLocaleDateString('es-ES')}\n\n`;
            if (risks && risks.length > 0) {
                risks.forEach(r => {
                    reportContent += `${r.id} - ${r.name} - Tipo: ${r.type} - Nivel: ${r.level} - Prob: ${r.probability} - Sev: ${r.severity}\n`;
                });
            } else {
                reportContent += 'No hay riesgos registrados.\n';
            }
            break;
        default:
            alert('Tipo de reporte no válido.');
            return;
    }

    // Mostrar en ventana nueva para mejor visualización
    const reportWindow = window.open('', '_blank', 'width=800,height=600');
    reportWindow.document.write(`
        <html>
            <head><title>${reportTitle}</title>
            <style>
                body { font-family: Arial, sans-serif; padding: 20px; white-space: pre-wrap; }
                h1 { color: #2563eb; }
            </style>
            </head>
            <body>
                <h1>${reportTitle}</h1>
                <pre>${reportContent}</pre>
                <button onclick="window.print()">🖨️ Imprimir</button>
                <button onclick="document.execCommand('selectAll'); document.execCommand('copy'); alert('Copiado al portapapeles')">📋 Copiar</button>
            </body>
        </html>
    `);
    reportWindow.document.close();
}

async function viewReport(type) {
    // Cargar datos necesarios
    if (!invList || invList.length === 0) await renderInventoryTable();
    if (!risks || risks.length === 0) await renderRisksTable();
    if (!eppList || eppList.length === 0) await renderEppTable();

    let reportData = [];
    let reportTitle = '';

    switch (type) {
        case 'assignedEpp':
            reportTitle = 'EPP Asignados';
            // Nota: La tabla tab_trabajadores_epp existe pero no hay endpoint para leerla aún
            // Por ahora mostramos inventario con stock > 0
            reportData = invList.filter(i => i.stock > 0).map(i => `${i.name} - Stock: ${i.stock}`);
            break;
        case 'expiredEpp':
            reportTitle = 'EPP Vencidos';
            const today = new Date();
            reportData = eppList.filter(e => {
                const expDate = new Date(e.exp_date);
                return expDate < today;
            }).map(e => `${e.name} - Vencimiento: ${e.exp_date}`);
            break;
        case 'highRisks':
            reportTitle = 'Riesgos Altos';
            reportData = risks.filter(r => r.level === 'ALTO' || r.level === 'MUY ALTO')
                .map(r => `${r.name} - Nivel: ${r.level} - Tipo: ${r.type}`);
            break;
        case 'medicalExams':
            reportTitle = 'Exámenes Médicos';
            // Nota: No hay tabla de exámenes médicos en BD, mostramos trabajadores activos como placeholder
            reportData = workers.filter(w => !w.fecha_retiro_trabajador).map(w => `${w.name} ${w.lastName} - ${w.id}`);
            break;
        default:
            alert('Tipo de reporte no válido.');
            return;
    }

    if (reportData.length === 0) {
        alert(`${reportTitle}\n\nNo hay registros para mostrar.`);
        return;
    }

    const reportWindow = window.open('', '_blank', 'width=800,height=600');
    reportWindow.document.write(`
        <html>
            <head><title>${reportTitle}</title>
            <style>
                body { font-family: Arial, sans-serif; padding: 20px; }
                h1 { color: #2563eb; }
                ul { list-style-type: none; padding: 0; }
                li { padding: 8px; border-bottom: 1px solid #e5e7eb; }
            </style>
            </head>
            <body>
                <h1>${reportTitle}</h1>
                <p>Fecha: ${new Date().toLocaleDateString('es-ES')}</p>
                <p>Total: ${reportData.length}</p>
                <ul>${reportData.map(item => `<li>${item}</li>`).join('')}</ul>
                <button onclick="window.print()">🖨️ Imprimir</button>
            </body>
        </html>
    `);
    reportWindow.document.close();
}

window.viewRisk = function (id) {
    // For now, view is same as edit
    window.editRisk(id);
};

// Funciones de búsqueda/filtrado básico (sin necesidad de campos adicionales en BD)
function filterEppTable() {
    const searchTerm = document.getElementById('searchEpp')?.value.toLowerCase() || '';
    const tbody = document.getElementById('eppTable');
    if (!tbody) return;
    const rows = tbody.querySelectorAll('tr');
    rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        row.style.display = text.includes(searchTerm) ? '' : 'none';
    });
}

function filterInventoryTable() {
    const searchTerm = document.getElementById('searchInventory')?.value.toLowerCase() || '';
    const tbody = document.getElementById('inventarioTable');
    if (!tbody) return;
    const rows = tbody.querySelectorAll('tr');
    rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        row.style.display = text.includes(searchTerm) ? '' : 'none';
    });
}

function filterWorkersTable() {
    const searchTerm = document.getElementById('searchWorkers')?.value.toLowerCase() || '';
    const tbody = document.getElementById('workersTable');
    if (!tbody) return;
    const rows = tbody.querySelectorAll('tr');
    rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        row.style.display = text.includes(searchTerm) ? '' : 'none';
    });
}

function filterRisksTable() {
    const searchTerm = document.getElementById('searchRisks')?.value.toLowerCase() || '';
    const tbody = document.getElementById('risksTable');
    if (!tbody) return;
    const rows = tbody.querySelectorAll('tr');
    rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        row.style.display = text.includes(searchTerm) ? '' : 'none';
    });
}

function filterArlTable() {
    const searchTerm = document.getElementById('searchArl')?.value.toLowerCase() || '';
    const tbody = document.getElementById('arlTable');
    if (!tbody) return;
    const rows = tbody.querySelectorAll('tr');
    rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        row.style.display = text.includes(searchTerm) ? '' : 'none';
    });
}

function filterEpsTable() {
    const searchTerm = document.getElementById('searchEps')?.value.toLowerCase() || '';
    const tbody = document.getElementById('epsTable');
    if (!tbody) return;
    const rows = tbody.querySelectorAll('tr');
    rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        row.style.display = text.includes(searchTerm) ? '' : 'none';
    });
}

function filterIpsTable() {
    const searchTerm = document.getElementById('searchIps')?.value.toLowerCase() || '';
    const tbody = document.getElementById('ipsTable');
    if (!tbody) return;
    const rows = tbody.querySelectorAll('tr');
    rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        row.style.display = text.includes(searchTerm) ? '' : 'none';
    });
}

function filterUsersTable() {
    const searchTerm = document.getElementById('searchUsers')?.value.toLowerCase() || '';
    const tbody = document.getElementById('usersTable');
    if (!tbody) return;
    const rows = tbody.querySelectorAll('tr');
    rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        row.style.display = text.includes(searchTerm) ? '' : 'none';
    });
}
