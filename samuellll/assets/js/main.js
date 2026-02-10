
// Globales para EPP e Inventario
let eppList = [];
let invList = [];
let workers = [];
let risks = [];
let usersList = [];
let arlList = [];
let epsList = [];
let ipsList = [];
let currentUser = JSON.parse(localStorage.getItem('user'));

// Ayudantes para Modales
function openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.style.display = 'flex'; // Forzar visibilidad
        // Pequeño tiempo de espera para permitir que el cambio de pantalla se registre antes de la transición de opacidad
        setTimeout(() => {
            modal.classList.add('active');
        }, 10);
    }
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.remove('active');
        // Esperar a que la transición termine antes de ocultar
        setTimeout(() => {
            modal.style.display = 'none';
        }, 300);
    }
}

// Clic en la ventana para cerrar modales
// Clic en la ventana para cerrar modales
window.onclick = function (event) {
    if (event.target.classList.contains('modal')) {
        closeModal(event.target.id);
    }
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
    if (document.getElementById('totalWorkers')) loadDashboardStats();

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
            if (document.getElementById('expiringSoon')) document.getElementById('expiringSoon').innerText = stats.expiringSoon;
        } else {
            console.error("Error loading stats:", response.status);
        }
    } catch (e) {
        console.error("Error fetching dashboard stats:", e);
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
    // La lógica de cierre de sesión es manejada por la etiqueta de anclaje en HTML

    // Formulario agregar usuario
    // Exponer para uso global
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

    // Formulario agregar Inventario (ID en HTML es addEppForm por legacy, lo dejé así en HTML pero es inventario)
    // Espera, en inventario.html el form ID es addEppForm.
    // Formulario agregar Inventario
    const addInventoryForm = document.getElementById('addEppForm');
    if (addInventoryForm) {
        addInventoryForm.addEventListener('submit', function (e) {
            e.preventDefault();
            saveInventory();
        });
    }

    // Formulario agregar EPP
    const addEquipmentForm = document.getElementById('addEquipmentForm');
    if (addEquipmentForm) {
        addEquipmentForm.addEventListener('submit', function (e) {
            e.preventDefault();
            saveEpp();
        });
    }

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
// RENDERIZAR TABLAS (API)
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
        usersList = usersData; // Global para edición

        tbody.innerHTML = '';
        if (usersData.length === 0) {
            tbody.innerHTML = '<tr><td colspan="7">No hay usuarios registrados.</td></tr>';
            return;
        }

        usersData.forEach(user => {
            const row = document.createElement('tr');
            const isActive = user.status === 'ACTIVO';
            row.innerHTML = `
                <td>${user.id}</td>
                <td>${user.fullName}</td>
                <td>${user.email}</td>
                <td><span class="role-badge ${user.role === 'ADMINISTRADOR' ? 'admin' : ''}">${user.role}</span></td>
                <td><span class="status-badge ${isActive ? 'status-active' : 'status-inactive'}">${user.status}</span></td>
                <td>${user.lastAccess || 'Nunca'}</td>
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
            // Usar clase específica para el coloreado de estado
            const statusClass = item.status === 'DISPONIBLE' ? 'status-active' : 'status-inactive';

            row.innerHTML = `
                    <td>${item.id}</td>
                    <td>${item.name}</td>
                    <td>${item.reference}</td>
                    <td>${item.brand_name || 'N/A'}</td>
                    <td>${item.category_name || 'N/A'}</td>
                    <td>${item.exp_date}</td>
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
        workers = workersData; // Actualizar global para estadísticas

        tbody.innerHTML = '';
        if (workersData.length === 0) {
            tbody.innerHTML = '<tr><td colspan="8">No hay trabajadores registrados.</td></tr>';
            return;
        }

        workersData.forEach(worker => {
            const row = document.createElement('tr');
            row.innerHTML = `
                <td>${worker.id}</td>
                <td>${worker.name} ${worker.lastName}</td>
                <td>${worker.position}</td>
                <td>${worker.startDate}</td>
                <td>${worker.arl}</td>
                <td>${worker.eps}</td>
                <td><span class="status-badge status-active">ACTIVO</span></td>
                <td>
                    <button class="btn btn-primary btn-sm" onclick="viewWorker('${worker.id}')">👁️</button>
                    <button class="btn btn-success btn-sm" onclick="editWorker('${worker.id}')">✏️</button>
                    <button class="btn btn-danger btn-sm" onclick="deleteWorker('${worker.id}')">🗑️</button>
                </td>
            `;
            tbody.appendChild(row);
        });

        // Actualizar contador de estadísticas
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

            row.innerHTML = `
                <td>${item.id}</td>
                <td>${item.name}</td>
                <td>${item.category}</td>
                <td>${item.brand}</td>
                <td>${item.stock}</td>
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
        // Añadir marca de tiempo para evitar el almacenamiento en caché (caching)
        const response = await fetch(`backend/api/risks/read.php?t=${new Date().getTime()}`, { headers: getAuthHeaders() });
        if (response.status === 401) { window.location.href = 'login.html'; return; }

        const data = await response.json();
        risks = Array.isArray(data) ? data : [];

        // Actualizar Dashboard (Matriz y Estadísticas)
        updateRiskDashboard(risks);

        tbody.innerHTML = '';
        if (risks.length === 0) {
            tbody.innerHTML = '<tr><td colspan="8">No hay riesgos registrados.</td></tr>';
            return;
        }

        risks.forEach(risk => {
            const row = document.createElement('tr');

            // Fallback de porcentaje
            let percent = risk.percentage;
            // Normalizar para el cálculo de fallback
            const pUpper = (risk.probability || '').trim().toUpperCase();
            const sUpper = (risk.severity || '').trim().toUpperCase();

            if (percent === undefined || percent === null) {
                const probVal = (pUpper === 'ALTA' ? 3 : (pUpper === 'MEDIA' ? 2 : 1));
                const sevVal = (sUpper === 'MUY GRAVE' ? 100 : (sUpper === 'GRAVE' ? 60 : (sUpper === 'MODERADA' ? 20 : 10)));
                percent = Math.round(((probVal * sevVal) / 300) * 100);
            }

            // Determinar color
            let barColor = '#10b981'; // Verde
            if (percent > 15) barColor = '#f59e0b'; // Amarillo/Naranja
            if (percent > 40) barColor = '#ef4444'; // Rojo

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

// Ayudante para colores de insignias (badges)
function getRiskLevelClass(level) {
    switch (level) {
        case 'BAJO': return 'status-active'; // Verdoso
        case 'MEDIO': return 'status-warning'; // Amarillento 
        case 'ALTO': return 'status-inactive'; // Rojizo
        case 'MUY ALTO': return 'status-inactive'; // Rojizo
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
// LÓGICA DEL DASHBOARD DE RIESGOS (Matriz y Estadísticas)
// -------------------------------------------------------------

function updateRiskDashboard(riskData) {
    // 1. Actualizar Tarjetas de Estadísticas (Filtrado insensible a mayúsculas/minúsculas)
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

    // Calcular % de Riesgo Promedio
    let avgPercent = 0;
    if (total > 0) {
        const sumPercent = riskData.reduce((acc, curr) => {
            let p = curr.percentage;
            // Normalizar para el cálculo de fallback
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

    // 2. Actualizar Matriz
    document.querySelectorAll('.matrix-cell').forEach(cell => {
        cell.innerHTML = '';
    });

    riskData.forEach(risk => {
        // Asegurar que los valores coincidan con el formato del ID (ej., MUY_GRAVE)
        let prob = (risk.probability || '').trim().toUpperCase();
        let sev = (risk.severity || '').trim().toUpperCase();

        // Normalizar valores específicos
        sev = sev.replace(/\s+/g, '_'); // Reemplazar espacios dentro del texto con guion bajo

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
    // Reiniciar/Recalcular nivel
    calculateRiskLevel();
    // ¿Deshabilitar edición manual del nivel?
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

    // Auto-establecer nivel basado en prob/sev actual
    calculateRiskLevel();
    document.getElementById('riskLevel').style.pointerEvents = 'none';
    document.getElementById('riskLevel').style.backgroundColor = '#f3f4f6';

    document.getElementById('riskDesc').value = risk.description;
    document.getElementById('riskMeasures').value = risk.measures;

    openModal('addRiskModal');
};

// Guardar Riesgo (Crear/Actualizar)
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
// ENTIDADES DE SALUD (ARL, EPS, IPS)
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
    const payload = {
        id: id || undefined,
        name: document.getElementById('arlName').value,
        nit: document.getElementById('arlNit').value,
        address: document.getElementById('arlAddress').value,
        phone: document.getElementById('arlPhone').value,
        email: document.getElementById('arlEmail').value
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
    const payload = {
        name: document.getElementById('epsName').value,
        address: document.getElementById('epsAddress').value,
        phone: document.getElementById('epsPhone').value,
        email: document.getElementById('epsEmail').value
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
    const payload = {
        name: document.getElementById('ipsName').value,
        address: document.getElementById('ipsAddress').value,
        phone: document.getElementById('ipsPhone').value,
        email: document.getElementById('ipsEmail').value
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
// FUNCIONES DE ADICIÓN (API)
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
// CRUD DE EPP
// -------------------------------------------------------------------------

async function loadBrandsAndCategories() {
    try {
        // Cargar Marcas
        const brandRes = await fetch('backend/api/brands/read.php', { headers: getAuthHeaders() });
        const brands = await brandRes.json();
        const brandSelect = document.getElementById('eppBrand');
        brandSelect.innerHTML = '<option value="">Seleccione Marca</option>';
        if (Array.isArray(brands)) {
            brands.forEach(b => {
                brandSelect.innerHTML += `<option value="${b.id}">${b.name}</option>`;
            });
        }

        // Cargar Categorías
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

    const eppData = {
        id: id,
        name: document.getElementById('eppName').value,
        type: document.getElementById('eppType').value,
        brand_id: brandVal,
        category_id: catVal,
        size: document.getElementById('eppSize').value,
        reference: document.getElementById('eppReference').value,
        manufacturer: document.getElementById('eppManufacturer').value,
        serial: document.getElementById('eppSerial').value,
        fab_date: document.getElementById('eppFabDate').value,
        exp_date: document.getElementById('eppExpDate').value,
        buy_date: document.getElementById('eppBuyDate').value,
        life_months: document.getElementById('eppLife').value,
        description: document.getElementById('eppDescription').value
    };

    try {
        const response = await fetch(url, getFetchOpts('POST', eppData));
        let err = {};
        try { err = await response.json(); } catch (_) { err = { message: await response.text() || 'Error del servidor' }; }

        if (response.ok) {
            alert(isUpdate ? 'EPP actualizado exitosamente' : 'EPP creado exitosamente');
            closeModal('addEquipmentModal');
            renderEppTable();
        } else {
            if (err.missing_fields) {
                alert('Faltan datos: ' + err.missing_fields.join(', '));
            } else {
                alert('Error: ' + (err.message || 'Error desconocido'));
            }
        }
    } catch (e) {
        console.error('saveEpp error:', e);
        alert('Error de conexión: ' + (e.message || 'Revise la consola'));
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
// CRUD DE INVENTARIO
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

    const invData = {
        id: id,
        epp_id: document.getElementById('invEppId').value,
        stock: document.getElementById('invStock').value,
        min_stock: document.getElementById('invMinStock').value,
        max_stock: document.getElementById('invMaxStock').value,
        reorder_point: document.getElementById('invReorder').value
    };

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(invData)
        });

        if (response.ok) {
            alert(isUpdate ? 'Inventario actualizado' : 'Inventario creado');
            closeModal('addEppModal');
            renderInventoryTable();
        } else {
            const err = await response.json();
            alert('Error: ' + err.message);
        }
    } catch (e) {
        console.error(e);
        alert('Error de conexión');
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
// CRUD DE USUARIOS
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

    const name = document.getElementById('userNameInput').value;
    const lastName = document.getElementById('userLastNameInput').value;
    const email = document.getElementById('userEmailInput').value;
    const password = document.getElementById('userPasswordInput').value;
    const confirmPassword = document.getElementById('userPasswordConfirm').value;
    const role = document.getElementById('userRoleSelect').value;
    const status = document.getElementById('userStatusSelect').value;

    if (!isUpdate && !password) {
        alert('La contraseña es obligatoria para nuevos usuarios');
        return;
    }

    if (password && password !== confirmPassword) {
        alert('Las contraseñas no coinciden');
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

// Reemplazar el antiguo addNewUser con el gancho (hook) saveUser
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
                renderUsersTable(); // Recargar tabla desde la BD
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
// CRUD DE TRABAJADORES
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
    const docNumber = document.getElementById('docNumber').value;
    const dbId = id || docNumber;
    const isUpdate = id !== '';
    const url = isUpdate ? 'backend/api/workers/update.php' : 'backend/api/workers/create.php';

    const workerData = {
        id: dbId,
        doc_type: document.getElementById('docType').value,
        name: document.getElementById('workerName').value,
        lastName: document.getElementById('workerLastName').value,
        position_id: document.getElementById('workerPosition').value,
        startDate: document.getElementById('workerStartDate').value,
        phone: document.getElementById('workerPhone').value,
        email: document.getElementById('workerEmail').value,
        address: document.getElementById('workerAddress') ? document.getElementById('workerAddress').value : '',
        rh: document.getElementById('workerRh') ? document.getElementById('workerRh').value : 'O+',
        sex: document.getElementById('workerSex') ? document.getElementById('workerSex').value : 'MASCULINO',
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

// Reemplazar el antiguo addNewWorker
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


function generateReport(type) {
    let reportContent = '';

    switch (type) {
        case 'workers':
            reportContent = `REPORTE DE TRABAJADORES\n\n`;
            workers.forEach(w => {
                reportContent += `${w.id} - ${w.name} ${w.lastName} - ${w.position}\n`;
            });
            break;
        case 'inventory':
            reportContent = `REPORTE DE INVENTARIO\n\n`;
            eppInventory.forEach(i => {
                reportContent += `${i.id} - ${i.name} - Stock: ${i.stock} - Estado: ${i.status}\n`;
            });
            break;
        case 'risks':
            reportContent = `REPORTE DE RIESGOS\n\n`;
            risks.forEach(r => {
                reportContent += `${r.id} - ${r.name} - Nivel: ${r.level}\n`;
            });
            break;
    }

    alert('Reporte generado:\n\n' + reportContent);
    // En producción, se generaría un PDF o Excel
}

function viewReport(type) {
    alert(`Viendo reporte de ${type} - Funcionalidad en desarrollo`);
}

window.viewRisk = function (id) {
    // For now, view is same as edit
    window.editRisk(id);
};

