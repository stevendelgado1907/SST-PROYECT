DROP TABLE IF EXISTS inventario_epp;
DROP TABLE IF EXISTS tab_trabajadores_epp;
DROP TABLE IF EXISTS tab_trabajadores_riesgos;
DROP TABLE IF EXISTS tab_trabajadores_arl_ips;
DROP TABLE IF EXISTS tab_trabajadores_arl_eps;
DROP TABLE IF EXISTS tab_epp;
DROP TABLE IF EXISTS tab_trabajadores;
DROP TABLE IF EXISTS tab_supervisores;
DROP TABLE IF EXISTS tab_riesgos;
DROP TABLE IF EXISTS tab_categorias;
DROP TABLE IF EXISTS tab_marcas;
DROP TABLE IF EXISTS tab_cargos;
DROP TABLE IF EXISTS tab_ips;
DROP TABLE IF EXISTS tab_eps;
DROP TABLE IF EXISTS tab_arl;
DROP TABLE IF EXISTS tab_usuarios;
DROP TABLE IF EXISTS tab_roles;

-- Tablas maestras/base
CREATE TABLE tab_roles (
    id_rol INTEGER NOT NULL ,
    nombre_rol VARCHAR(50) NOT NULL UNIQUE,
    PRIMARY KEY (id_rol)
);

CREATE TABLE tab_usuarios (
    id_usuario INTEGER NOT NULL ,
    correo_usuario VARCHAR(150) UNIQUE NOT NULL,
    pass_hash VARCHAR(255) NOT NULL,
    id_rol INTEGER NOT NULL,   
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ultimo_acceso TIMESTAMP,
    estado_usuario VARCHAR(50) DEFAULT 'ACTIVO',
    nombre_usuario VARCHAR(100),
    apellido_usuario VARCHAR(100),
    PRIMARY KEY (id_usuario),
    FOREIGN KEY (id_rol) REFERENCES tab_roles(id_rol)
);

CREATE TABLE tab_arl(
    id_arl INTEGER NOT NULL ,
    nom_arl VARCHAR(100) NOT NULL,
    nit_arl VARCHAR(20) NOT NULL UNIQUE,
    direccion_arl VARCHAR(200) NOT NULL,
    tel_arl VARCHAR(15) NOT NULL,
    correo_arl VARCHAR(100),
    PRIMARY KEY (id_arl)
);

CREATE TABLE tab_eps(
    id_eps INTEGER NOT NULL,
    nom_eps VARCHAR(100) NOT NULL UNIQUE,
    direccion_eps VARCHAR(200) NOT NULL,
    tel_eps VARCHAR(15) NOT NULL,
    correo_eps VARCHAR(100),
    PRIMARY KEY (id_eps)
);

CREATE TABLE tab_ips(
    id_ips INTEGER NOT NULL ,
    nom_ips VARCHAR(100) NOT NULL UNIQUE,
    direccion_ips VARCHAR(200) NOT NULL,
    tel_ips VARCHAR(15) NOT NULL,
    correo_ips VARCHAR(100),
    PRIMARY KEY (id_ips)
);

CREATE TABLE tab_cargos(
    id_cargo INTEGER NOT NULL,
    nom_cargo VARCHAR(100) NOT NULL UNIQUE,
    descripcion_cargo VARCHAR(255) NOT NULL,
    nivel_riesgo_cargo VARCHAR(50) NOT NULL,
    salario_base DECIMAL(10,2) NOT NULL,
    departamento VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_cargo)
);

CREATE TABLE tab_marcas(
    id_marca INTEGER NOT NULL,
    nom_marca VARCHAR(100) NOT NULL UNIQUE,
    proveedor_marca VARCHAR(100) NOT NULL,
    contacto_proveedor VARCHAR(15) NOT NULL,
    PRIMARY KEY (id_marca)
);

CREATE TABLE tab_categorias(
    id_categoria INTEGER NOT NULL,
    nom_categoria VARCHAR(100) NOT NULL UNIQUE,
    descripcion_categoria VARCHAR(255) NOT NULL,
    PRIMARY KEY (id_categoria)
);

CREATE TABLE tab_riesgos(
    id_riesgo INTEGER NOT NULL,
    nom_riesgo VARCHAR(100) NOT NULL UNIQUE,
    tipo_riesgo VARCHAR(100) NOT NULL,
    descripcion_riesgo TEXT NOT NULL,
    nivel_de_riesgo VARCHAR(50) NOT NULL,
    probabilidad_riesgo VARCHAR(50) NOT NULL,
    severidad_riesgo VARCHAR(50) NOT NULL,
    medidas_control VARCHAR(255) NOT NULL,
    PRIMARY KEY (id_riesgo)
);

CREATE TABLE tab_supervisores(
    id_supervisor INTEGER NOT NULL,
    nom_supervisor VARCHAR(100) NOT NULL,
    ape_supervisor VARCHAR(100) NOT NULL,
    correo_supervisor VARCHAR(100) NOT NULL UNIQUE,
    tel_supervisor VARCHAR(15) NOT NULL,
    fecha_ingreso_supervisor DATE NOT NULL,
    fecha_retiro_supervisor DATE,
    certificacion_supervisor VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_supervisor)
);

-- Tabla de trabajadores (CORREGIDA: id_trabajador como VARCHAR para documentos)
CREATE TABLE tab_trabajadores(
    id_trabajador VARCHAR(20) NOT NULL,  -- Documento de identidad
    tipo_documento VARCHAR(3) DEFAULT 'CC',  -- CC, CE, NIT, PAS, TI
    id_cargo INTEGER NOT NULL,
    nom_trabajador VARCHAR(100) NOT NULL,
    ape_trabajador VARCHAR(100) NOT NULL,
    tel_trabajador VARCHAR(15) NOT NULL,
    correo_trabajador VARCHAR(100) NOT NULL UNIQUE,
    direccion_trabajador VARCHAR(200) NOT NULL,
    rh_trabajador VARCHAR(5) NOT NULL,
    sexo_trabajador VARCHAR(10) NOT NULL,
    fecha_ingreso_trabajador DATE NOT NULL,
    fecha_retiro_trabajador DATE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_trabajador),
    FOREIGN KEY (id_cargo) REFERENCES tab_cargos(id_cargo),
    CHECK (tipo_documento IN ('CC', 'CE', 'NIT', 'PAS', 'TI')),
    CHECK (sexo_trabajador IN ('MASCULINO', 'FEMENINO', 'OTRO'))
);

CREATE TABLE tab_epp(
    id_epp INTEGER NOT NULL,
    id_marca INTEGER NOT NULL,
    id_categoria INTEGER NOT NULL,
    talla_epp VARCHAR(50) NOT NULL,
    nom_epp VARCHAR(100) NOT NULL,
    tipo_epp VARCHAR(100) NOT NULL,
    referencia_epp VARCHAR(100) NOT NULL,
    fabricante_epp VARCHAR(100) NOT NULL,
    nro_serie_epp VARCHAR(100) NOT NULL UNIQUE,
    descripcion_epp VARCHAR(255) NOT NULL,
    fecha_fabricacion_epp DATE NOT NULL,
    fecha_vencimiento_epp DATE NOT NULL,
    fecha_compra_epp DATE NOT NULL,
    vida_util_meses INTEGER NOT NULL,
    estado_epp VARCHAR(50) DEFAULT 'DISPONIBLE',
    PRIMARY KEY (id_epp),
    FOREIGN KEY (id_marca) REFERENCES tab_marcas(id_marca),
    FOREIGN KEY (id_categoria) REFERENCES tab_categorias(id_categoria),
    CHECK (vida_util_meses > 0)
);

-- Tablas intermedias transaccionales
CREATE TABLE tab_trabajadores_arl_eps(
    id_trabajador_arl_eps INTEGER NOT NULL,
    id_trabajador VARCHAR(20) NOT NULL,
    id_arl INTEGER NOT NULL,
    id_eps INTEGER NOT NULL,
    fecha_afiliacion DATE NOT NULL,
    fecha_retiro DATE,
    PRIMARY KEY (id_trabajador_arl_eps),
    FOREIGN KEY (id_trabajador) REFERENCES tab_trabajadores(id_trabajador),
    FOREIGN KEY (id_arl) REFERENCES tab_arl(id_arl),
    FOREIGN KEY (id_eps) REFERENCES tab_eps(id_eps),
    UNIQUE (id_trabajador, id_arl, id_eps, fecha_afiliacion)
);

CREATE TABLE tab_trabajadores_arl_ips(
    id_trabajador_arl_ips INTEGER NOT NULL,
    id_trabajador VARCHAR(20) NOT NULL,
    id_arl INTEGER NOT NULL,
    id_ips INTEGER NOT NULL,
    fecha_afiliacion DATE NOT NULL,
    fecha_retiro DATE,
    PRIMARY KEY (id_trabajador_arl_ips),
    FOREIGN KEY (id_trabajador) REFERENCES tab_trabajadores(id_trabajador),
    FOREIGN KEY (id_arl) REFERENCES tab_arl(id_arl),
    FOREIGN KEY (id_ips) REFERENCES tab_ips(id_ips),
    UNIQUE (id_trabajador, id_arl, id_ips, fecha_afiliacion)
);

CREATE TABLE tab_trabajadores_riesgos(
    id_trabajador_riesgo INTEGER NOT NULL,
    id_trabajador VARCHAR(20) NOT NULL,
    id_riesgo INTEGER NOT NULL,
    fecha_asignacion DATE NOT NULL,
    fecha_retiro DATE,
    observaciones TEXT,
    PRIMARY KEY (id_trabajador_riesgo),
    FOREIGN KEY (id_trabajador) REFERENCES tab_trabajadores(id_trabajador),
    FOREIGN KEY (id_riesgo) REFERENCES tab_riesgos(id_riesgo),
    UNIQUE (id_trabajador, id_riesgo, fecha_asignacion)
);

CREATE TABLE tab_trabajadores_epp(
    id_trabajador_epp INTEGER NOT NULL,
    id_trabajador VARCHAR(20) NOT NULL,
    id_epp INTEGER NOT NULL,
    fecha_asignacion DATE NOT NULL,
    fecha_devolucion DATE,
    fecha_retiro DATE,
    estado_epp VARCHAR(50) NOT NULL DEFAULT 'ASIGNADO',
    observaciones TEXT,
    PRIMARY KEY (id_trabajador_epp),
    FOREIGN KEY (id_trabajador) REFERENCES tab_trabajadores(id_trabajador),
    FOREIGN KEY (id_epp) REFERENCES tab_epp(id_epp),
    CHECK (estado_epp IN ('ASIGNADO', 'EN_USO', 'DEVUELTO', 'DANADO', 'PERDIDO'))
);

-- Tabla de inventario
CREATE TABLE inventario_epp(
    id_inventario INTEGER NOT NULL,
    id_epp INTEGER NOT NULL UNIQUE,
    stock_actual INTEGER NOT NULL DEFAULT 0,
    stock_minimo INTEGER NOT NULL DEFAULT 10,
    stock_maximo INTEGER NOT NULL DEFAULT 100,
    punto_reorden INTEGER NOT NULL DEFAULT 20,
    ultima_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_inventario),
    FOREIGN KEY (id_epp) REFERENCES tab_epp(id_epp),
    CHECK (stock_actual >= 0),
    CHECK (stock_minimo >= 0),
    CHECK (stock_maximo > stock_minimo),
    CHECK (punto_reorden BETWEEN stock_minimo AND stock_maximo)
);

-- Índices para mejor performance
CREATE INDEX idx_trabajadores_cargo ON tab_trabajadores(id_cargo);
CREATE INDEX idx_trabajadores_estado ON tab_trabajadores(fecha_retiro_trabajador);
CREATE INDEX idx_trabajadores_documento ON tab_trabajadores(id_trabajador);
CREATE INDEX idx_trabajadores_nombre ON tab_trabajadores(nom_trabajador, ape_trabajador);
CREATE INDEX idx_trabajadores_epp ON tab_trabajadores_epp(id_trabajador, id_epp);
CREATE INDEX idx_trabajadores_riesgos ON tab_trabajadores_riesgos(id_trabajador, id_riesgo);
CREATE INDEX idx_epp_categoria ON tab_epp(id_categoria);
CREATE INDEX idx_epp_marca ON tab_epp(id_marca);