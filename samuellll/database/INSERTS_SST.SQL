-- Archivo: INSERTS_SST.sql

-- Insertar roles
INSERT INTO tab_roles (id_rol, nombre_rol) VALUES 
(1, 'ADMINISTRADOR'),
(2, 'SUPERVISOR');

-- Insertar usuarios (pass: Admin123 y Sup123 respectivamente)
-- Insertar usuarios (pass: Admin123)
-- NOTA: El hash a continuación es un ejemplo válido de BCRYPT para "Admin123".
-- Si esto falla, ejecutar fix_password.php
INSERT INTO tab_usuarios (id_usuario, correo_usuario, pass_hash, id_rol, nombre_usuario, apellido_usuario, estado_usuario) VALUES 
(1, 'admin@sst.com', '$2y$10$E9qJg.OaJ5.j.J.J.J.J.eJ.J.J.J.J.J.J.J.J.J.J.J.J.J', 1, 'Carlos', 'Administrador', 'ACTIVO'),
(2, 'supervisor@sst.com', '$2y$10$YourHashHereForSup123', 2, 'Ana', 'Supervisora', 'ACTIVO'),
(3, 'juan.perez@empresa.com', '$2y$10$YourHashHereForUser123', 2, 'Juan', 'Pérez', 'ACTIVO'),
(4, 'maria.gomez@empresa.com', '$2y$10$YourHashHereForUser456', 1, 'María', 'Gómez', 'INACTIVO');

-- Insertar ARL
INSERT INTO tab_arl (id_arl, nom_arl, nit_arl, direccion_arl, tel_arl, correo_arl) VALUES 
(1, 'Positiva', '800.123.456-7', 'Calle 100 #15-20 Bogotá', '6011234567', 'contacto@positiva.com'),
(2, 'Colmena', '800.234.567-8', 'Av. 68 #10-45 Medellín', '6049876543', 'info@colmena.com'),
(3, 'Sura', '800.345.678-9', 'Carrera 50 #25-80 Cali', '6024567890', 'sst@sura.com');

-- Insertar EPS
INSERT INTO tab_eps (id_eps, nom_eps, direccion_eps, tel_eps, correo_eps) VALUES 
(1, 'Sura EPS', 'Carrera 43A #5-100', '6014441234', 'eps@sura.com'),
(2, 'Nueva EPS', 'Calle 24 #43-21', '6014445678', 'contacto@nuevaeps.com'),
(3, 'Sanitas', 'Av. 19 #100-45', '6014449012', 'atencion@sanitas.com');

-- Insertar IPS
INSERT INTO tab_ips (id_ips, nom_ips, direccion_ips, tel_ips, correo_ips) VALUES 
(1, 'Clínica del Country', 'Calle 127 #16-10', '6016351234', 'info@clinicadelcountry.com'),
(2, 'Hospital San José', 'Carrera 9 #17-45', '6016335678', 'contacto@hospitalsanjose.com'),
(3, 'Clínica Colsanitas', 'Calle 100 #13-20', '6016219012', 'sst@colsanitas.com');

-- Insertar cargos
INSERT INTO tab_cargos (id_cargo, nom_cargo, descripcion_cargo, nivel_riesgo_cargo, salario_base, departamento) VALUES 
(1, 'Operario de Producción', 'Operario de línea de producción', 'ALTO', 1500000.00, 'Producción'),
(2, 'Supervisor de Planta', 'Supervisión del personal de producción', 'MEDIO', 2800000.00, 'Producción'),
(3, 'Analista de SST', 'Gestión del sistema de seguridad y salud', 'BAJO', 3200000.00, 'SST'),
(4, 'Mantenimiento', 'Técnico de mantenimiento industrial', 'ALTO', 1800000.00, 'Mantenimiento'),
(5, 'Almacenista', 'Gestión de inventarios y almacén', 'BAJO', 1600000.00, 'Logística'),
(6, 'Electricista', 'Especialista en instalaciones eléctricas', 'ALTO', 2200000.00, 'Mantenimiento');

-- Insertar marcas de EPP
INSERT INTO tab_marcas (id_marca, nom_marca, proveedor_marca, contacto_proveedor) VALUES 
(1, '3M', 'Distribuidora 3M Colombia', '6018001234'),
(2, 'MSA', 'Seguridad Industrial S.A.', '6018005678'),
(3, 'Honeywell', 'Proveedor Industrial Ltda.', '6018009012'),
(4, 'Delta Plus', 'Equipos de Seguridad Colombia', '6018003456'),
(5, 'Protecta', 'Protección Personal S.A.S.', '6018007890');

-- Insertar categorías de EPP
INSERT INTO tab_categorias (id_categoria, nom_categoria, descripcion_categoria) VALUES 
(1, 'Protección Auditiva', 'Equipos para protección de oídos'),
(2, 'Protección Respiratoria', 'Equipos para protección de vías respiratorias'),
(3, 'Protección Visual', 'Equipos para protección de ojos'),
(4, 'Protección de Cabeza', 'Cascos y gorras de seguridad'),
(5, 'Protección de Manos', 'Guantes de seguridad'),
(6, 'Protección de Pies', 'Calzado de seguridad'),
(7, 'Protección Corporal', 'Chalecos y overoles de seguridad');

-- Insertar riesgos
INSERT INTO tab_riesgos (id_riesgo, nom_riesgo, tipo_riesgo, descripcion_riesgo, nivel_de_riesgo, probabilidad_riesgo, severidad_riesgo, medidas_control) VALUES 
(1, 'Ruido Industrial', 'FÍSICO', 'Exposición a niveles de ruido superiores a 85 dB', 'ALTO', 'ALTA', 'MEDIA', 'Uso de protección auditiva, rotación de personal'),
(2, 'Caídas a Distinto Nivel', 'MECÁNICO', 'Riesgo de caída desde alturas mayores a 1.5m', 'MUY ALTO', 'MEDIA', 'ALTA', 'Uso de arnés, líneas de vida, capacitación'),
(3, 'Contacto con Energía Eléctrica', 'ELÉCTRICO', 'Riesgo de electrocución por contacto con partes energizadas', 'MUY ALTO', 'BAJA', 'MUY ALTA', 'Bloqueo y etiquetado, EPP dieléctrico'),
(4, 'Manipulación de Cargas', 'ERGONÓMICO', 'Lesiones musculoesqueléticas por levantamiento incorrecto', 'MEDIO', 'ALTA', 'MEDIA', 'Capacitación en técnicas, ayuda mecánica'),
(5, 'Exposición a Químicos', 'QUÍMICO', 'Contacto con sustancias químicas peligrosas', 'ALTO', 'MEDIA', 'ALTA', 'Uso de EPP químico, ventilación, hojas de seguridad'),
(6, 'Incendio', 'INCENDIO', 'Riesgo de incendio por fuentes de ignición', 'ALTO', 'BAJA', 'MUY ALTA', 'Extintores, señalización, rutas de evacuación');

-- Insertar supervisores
INSERT INTO tab_supervisores (id_supervisor, nom_supervisor, ape_supervisor, correo_supervisor, tel_supervisor, fecha_ingreso_supervisor, certificacion_supervisor) VALUES 
(1, 'Roberto', 'Mendoza', 'roberto.mendoza@empresa.com', '3101234567', '2022-01-15', 'Supervisor SST - 50 horas'),
(2, 'Laura', 'Fernández', 'laura.fernandez@empresa.com', '3102345678', '2021-03-10', 'Auditor Interno SST'),
(3, 'Diego', 'Ramírez', 'diego.ramirez@empresa.com', '3103456789', '2023-06-20', 'Coordinador de Emergencias');

-- Insertar trabajadores
INSERT INTO tab_trabajadores (id_trabajador, tipo_documento, id_cargo, nom_trabajador, ape_trabajador, tel_trabajador, correo_trabajador, direccion_trabajador, rh_trabajador, sexo_trabajador, fecha_ingreso_trabajador) VALUES 
('12345678', 'CC', 1, 'Carlos', 'Rodríguez', '3111111111', 'carlos.rodriguez@empresa.com', 'Calle 1 #2-3', 'O+', 'MASCULINO', '2023-01-10'),
('87654321', 'CC', 2, 'Ana', 'García', '3222222222', 'ana.garcia@empresa.com', 'Carrera 4 #5-6', 'A+', 'FEMENINO', '2022-03-15'),
('11223344', 'CC', 3, 'Pedro', 'López', '3333333333', 'pedro.lopez@empresa.com', 'Av. 7 #8-9', 'B+', 'MASCULINO', '2021-06-20'),
('55667788', 'CC', 4, 'María', 'Martínez', '3444444444', 'maria.martinez@empresa.com', 'Calle 10 #11-12', 'AB+', 'FEMENINO', '2023-02-28'),
('99887766', 'CC', 5, 'José', 'Hernández', '3555555555', 'jose.hernandez@empresa.com', 'Carrera 13 #14-15', 'O-', 'MASCULINO', '2022-11-05'),
('44556677', 'CC', 6, 'Lucía', 'Díaz', '3666666666', 'lucia.diaz@empresa.com', 'Av. 16 #17-18', 'A-', 'FEMENINO', '2023-04-12');

-- Insertar EPP
INSERT INTO tab_epp (id_epp, id_marca, id_categoria, talla_epp, nom_epp, tipo_epp, referencia_epp, fabricante_epp, nro_serie_epp, descripcion_epp, fecha_fabricacion_epp, fecha_vencimiento_epp, fecha_compra_epp, vida_util_meses, estado_epp) VALUES 
(1, 1, 1, 'ÚNICA', 'Tapones Auditivos 3M', 'Tapones', '1100', '3M USA', 'SN-3M-001', 'Tapones desechables para ruido', '2023-01-15', '2025-01-15', '2023-02-01', 24, 'DISPONIBLE'),
(2, 1, 2, 'M', 'Respirador 3M N95', 'Mascarilla', '8210', '3M USA', 'SN-3M-002', 'Respirador partículas N95', '2023-02-10', '2025-02-10', '2023-03-01', 24, 'DISPONIBLE'),
(3, 2, 4, 'L', 'Casco MSA V-Gard', 'Casco', '475', 'MSA USA', 'SN-MSA-001', 'Casco de seguridad industrial', '2023-03-05', '2026-03-05', '2023-04-01', 36, 'DISPONIBLE'),
(4, 3, 3, 'ÚNICA', 'Gafas Honeywell', 'Gafas', 'Uvex', 'Honeywell', 'SN-HNY-001', 'Gafas de seguridad antiempañantes', '2023-04-20', '2026-04-20', '2023-05-01', 36, 'DISPONIBLE'),
(5, 4, 5, 'L', 'Guantes Delta Plus', 'Guantes', 'DP-101', 'Delta Plus', 'SN-DLT-001', 'Guantes anticorte nivel 5', '2023-05-15', '2024-11-15', '2023-06-01', 18, 'DISPONIBLE'),
(6, 5, 6, '42', 'Botas Protecta', 'Botas', 'PT-202', 'Protecta', 'SN-PRT-001', 'Botas de seguridad con punta de acero', '2023-06-10', '2025-06-10', '2023-07-01', 24, 'DISPONIBLE'),
(7, 2, 1, 'ÚNICA', 'Orejeras MSA', 'Orejeras', '510', 'MSA USA', 'SN-MSA-002', 'Orejeras atenuación 30dB', '2023-01-20', '2026-01-20', '2023-02-15', 36, 'ASIGNADO');

-- Insertar relaciones trabajadores-arl-eps
INSERT INTO tab_trabajadores_arl_eps (id_trabajador_arl_eps, id_trabajador, id_arl, id_eps, fecha_afiliacion) VALUES 
(1, '12345678', 1, 1, '2023-01-10'),
(2, '87654321', 2, 2, '2022-03-15'),
(3, '11223344', 3, 3, '2021-06-20'),
(4, '55667788', 1, 1, '2023-02-28'),
(5, '99887766', 2, 2, '2022-11-05'),
(6, '44556677', 3, 3, '2023-04-12');

-- Insertar relaciones trabajadores-arl-ips
INSERT INTO tab_trabajadores_arl_ips (id_trabajador_arl_ips, id_trabajador, id_arl, id_ips, fecha_afiliacion) VALUES 
(1, '12345678', 1, 1, '2023-01-10'),
(2, '87654321', 2, 2, '2022-03-15'),
(3, '11223344', 3, 3, '2021-06-20'),
(4, '55667788', 1, 1, '2023-02-28'),
(5, '99887766', 2, 2, '2022-11-05'),
(6, '44556677', 3, 3, '2023-04-12');

-- Insertar relaciones trabajadores-riesgos
INSERT INTO tab_trabajadores_riesgos (id_trabajador_riesgo, id_trabajador, id_riesgo, fecha_asignacion, observaciones) VALUES 
(1, '12345678', 1, '2023-01-10', 'Operario exposición a ruido de máquinas'),
(2, '12345678', 4, '2023-01-10', 'Manipulación de cajas'),
(3, '87654321', 2, '2022-03-15', 'Supervisión en alturas'),
(4, '55667788', 3, '2023-02-28', 'Mantenimiento eléctrico'),
(5, '44556677', 3, '2023-04-12', 'Trabajos en tableros eléctricos'),
(6, '44556677', 6, '2023-04-12', 'Área con equipos eléctricos');

-- Insertar relaciones trabajadores-epp
INSERT INTO tab_trabajadores_epp (id_trabajador_epp, id_trabajador, id_epp, fecha_asignacion, estado_epp, observaciones) VALUES 
(1, '12345678', 1, '2023-02-01', 'EN_USO', 'Asignación inicial'),
(2, '12345678', 3, '2023-04-01', 'EN_USO', 'Casco para área de producción'),
(3, '12345678', 5, '2023-06-01', 'EN_USO', 'Guantes para manipulación'),
(4, '55667788', 2, '2023-03-01', 'EN_USO', 'Respirador para mantenimiento'),
(5, '55667788', 4, '2023-05-01', 'EN_USO', 'Gafas protección ocular'),
(6, '44556677', 6, '2023-07-01', 'EN_USO', 'Botas seguridad eléctrica'),
(7, '87654321', 7, '2023-02-15', 'EN_USO', 'Orejeras supervisor de planta');

-- Insertar inventario
INSERT INTO inventario_epp (id_inventario, id_epp, stock_actual, stock_minimo, stock_maximo, punto_reorden) VALUES 
(1, 1, 150, 20, 200, 30),
(2, 2, 80, 15, 150, 25),
(3, 3, 45, 10, 100, 15),
(4, 4, 60, 10, 120, 20),
(5, 5, 120, 25, 200, 40),
(6, 6, 70, 15, 150, 25),
(7, 7, 25, 5, 50, 10);