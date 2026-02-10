/**
 * riesgos.js
 * Gestión de la Matriz de Riesgos - Protego
 */

document.addEventListener('DOMContentLoaded', () => {
    loadOptions();
    loadMatrix();
    loadRisks();
});

// Variables globales para opciones
let areasMap = {};
let typesMap = {};

// Cargar opciones para los selectores
async function loadOptions() {
    try {
        const response = await fetch('backend/api/riesgos/options.php');
        const data = await response.json();

        // Populate Areas
        const areaSelect = document.getElementById('area_id');
        areaSelect.innerHTML = '<option value="">Seleccione...</option>';
        data.areas.forEach(area => {
            const option = document.createElement('option');
            option.value = area.id;
            option.textContent = area.nombre;
            areaSelect.appendChild(option);
            areasMap[area.id] = area.nombre;
        });

        // Populate Types
        const typeSelect = document.getElementById('tipo_riesgo_id');
        typeSelect.innerHTML = '<option value="">Seleccione...</option>';
        data.tipos.forEach(type => {
            const option = document.createElement('option');
            option.value = type.id;
            option.textContent = type.nombre;
            typeSelect.appendChild(option);
            typesMap[type.id] = type;
        });

        // Populate Processes (Optional, dependent on area if implemented properly, simplified here)
        const processSelect = document.getElementById('proceso_id');
        processSelect.innerHTML = '<option value="">Seleccione...</option>';
        data.procesos.forEach(proc => {
            const option = document.createElement('option');
            option.value = proc.id;
            option.textContent = `${proc.nombre} (ID: ${proc.area_id})`; // Simplify showing area
            processSelect.appendChild(option);
        });

    } catch (error) {
        console.error('Error loading options:', error);
    }
}

// Calcular Nivel de Riesgo en tiempo real en el formulario
function calculateRiskLevel() {
    const prob = parseInt(document.getElementById('probabilidad').value) || 0;
    const imp = parseInt(document.getElementById('impacto').value) || 0;
    const levelInput = document.getElementById('nivel_calculado');

    const result = prob * imp;
    let label = '';
    let color = '';

    if (result <= 5) {
        label = `BAJO (${result})`;
        color = '#28a745'; // Green
    } else if (result <= 12) {
        label = `MEDIO (${result})`;
        color = '#ffc107'; // Yellow
    } else if (result <= 20) {
        label = `ALTO (${result})`;
        color = '#fd7e14'; // Orange
    } else {
        label = `EXTREMO (${result})`;
        color = '#dc3545'; // Red
    }

    if (prob > 0 && imp > 0) {
        levelInput.value = label;
        levelInput.style.color = 'white';
        levelInput.style.backgroundColor = color;
        levelInput.style.fontWeight = 'bold';
    } else {
        levelInput.value = '';
        levelInput.style.backgroundColor = '#f3f4f6';
    }
}

// Cargar y renderizar la matriz de calor
async function loadMatrix() {
    try {
        const response = await fetch('backend/api/riesgos/matrix.php');
        const data = await response.json();

        // Reset Cells
        document.querySelectorAll('.matrix-cell').forEach(cell => {
            cell.textContent = '';
            cell.className = 'matrix-cell'; // Reset classes
        });

        // Fill Matrix
        data.matrix.forEach(item => {
            const prob = item.probabilidad;
            const imp = item.impacto;
            const cellId = `cell-${prob}-${imp}`;
            const cell = document.getElementById(cellId);

            if (cell) {
                cell.textContent = item.cantidad;
                // Add color class
                let colorClass = '';
                if (item.categoria_riesgo === 'BAJO') colorClass = 'low';
                if (item.categoria_riesgo === 'MEDIO') colorClass = 'medium';
                if (item.categoria_riesgo === 'ALTO') colorClass = 'high';
                if (item.categoria_riesgo === 'EXTREMO') colorClass = 'extreme'; // or 'very-high' in css?

                // Check CSS classes in style.css or use internal mapping
                // Assuming style.css maps: .low, .medium, .high, .extreme (or .very-high)
                // Let's use inline style for safety if classes vary, or assume standard names
                cell.classList.add(colorClass || 'low');

                // Make clickable
                cell.style.cursor = 'pointer';
                cell.onclick = () => filterRisks(prob, imp);
            }
        });

        // Update Stats
        if (data.stats) {
            document.getElementById('totalRisksCount').textContent = data.stats.total || 0;
            document.getElementById('extremeRisksCount').textContent = data.stats.extremos || 0;
            document.getElementById('highRisksCount').textContent = data.stats.altos || 0;
            document.getElementById('mediumRisksCount').textContent = data.stats.medios || 0;
            document.getElementById('lowRisksCount').textContent = data.stats.bajos || 0;
            document.getElementById('avgRiskLevel').textContent = parseFloat(data.stats.riesgo_promedio || 0).toFixed(1);
        }

    } catch (error) {
        console.error('Error loading matrix:', error);
    }
}

// Cargar Tabla de Riesgos
async function loadRisks() {
    try {
        const response = await fetch('backend/api/riesgos/read.php');
        const risks = await response.json();
        renderTable(risks);
    } catch (error) {
        console.error('Error loading risks:', error);
    }
}

function renderTable(risks) {
    const tbody = document.getElementById('risksTable');
    tbody.innerHTML = '';

    if (risks.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7">No hay riesgos registrados.</td></tr>';
        return;
    }

    risks.forEach(risk => {
        const tr = document.createElement('tr');

        let badgeClass = 'badge-secondary';
        if (risk.categoria_riesgo === 'BAJO') badgeClass = 'badge-success';
        if (risk.categoria_riesgo === 'MEDIO') badgeClass = 'badge-warning';
        if (risk.categoria_riesgo === 'ALTO') badgeClass = 'badge-orange';
        if (risk.categoria_riesgo === 'EXTREMO') badgeClass = 'badge-danger';

        tr.innerHTML = `
            <td>#${risk.id}</td>
            <td>${risk.peligro}</td>
            <td>${risk.area_nombre}</td>
            <td><span class="badge" style="background-color: ${risk.tipo_color}; color: white;">${risk.tipo_nombre}</span></td>
            <td><span class="badge ${badgeClass}">${risk.categoria_riesgo} (${risk.nivel_riesgo})</span></td>
            <td>${risk.estado}</td>
            <td>
                <button class="btn-sm btn-info" onclick="viewRisk(${risk.id})">👁️</button>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

// Modal Helpers
function prepareAddRisk() {
    document.getElementById('addRiskForm').reset();
    document.getElementById('riskId').value = '';
    document.getElementById('nivel_calculado').value = '';
    document.getElementById('nivel_calculado').style.backgroundColor = '#f3f4f6';
    openModal('addRiskModal');
}

function openModal(modalId) {
    document.getElementById(modalId).style.display = 'block';
}

function closeModal(modalId) {
    document.getElementById(modalId).style.display = 'none';
}

// Form Submission
document.getElementById('addRiskForm').addEventListener('submit', async (e) => {
    e.preventDefault();

    // Validar selects
    if (!document.getElementById('area_id').value || !document.getElementById('tipo_riesgo_id').value) {
        alert("Por favor complete los campos obligatorios");
        return;
    }

    const formData = new FormData(e.target);
    const data = Object.fromEntries(formData.entries());

    try {
        const response = await fetch('backend/api/riesgos/create.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        });

        const result = await response.json();

        if (response.ok) {
            alert('Riesgo guardado exitosamente');
            closeModal('addRiskModal');
            loadMatrix(); // Refresh matrix
            loadRisks();  // Refresh table
        } else {
            alert('Error: ' + result.message);
        }
    } catch (error) {
        console.error('Error saving risk:', error);
        alert('Error al guardar el riesgo');
    }
});

// CSS styles moved to assets/css/style.css
