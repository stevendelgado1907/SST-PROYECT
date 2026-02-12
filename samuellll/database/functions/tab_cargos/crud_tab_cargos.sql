-- CRUD para tab_cargos
-- Archivo: database/functions/tab_cargos/crud_tab_cargos.sql

-- Función para Insertar Cargo
CREATE OR REPLACE FUNCTION fn_tab_cargos_insert(
    p_id_cargo INTEGER,
    p_nom_cargo VARCHAR(100),
    p_descripcion_cargo VARCHAR(255),
    p_nivel_riesgo_cargo VARCHAR(50),
    p_salario_base DECIMAL(10,2),
    p_departamento VARCHAR(100)
)
RETURNS TABLE (id_cargo INTEGER, nom_cargo VARCHAR) AS $$
BEGIN
    -- Validaciones de Nulidad
    IF p_id_cargo IS NULL THEN RAISE EXCEPTION 'El ID del cargo es obligatorio'; END IF;
    IF p_nom_cargo IS NULL OR TRIM(p_nom_cargo) = '' THEN RAISE EXCEPTION 'El nombre del cargo es obligatorio'; END IF;
    IF p_salario_base IS NULL OR p_salario_base < 0 THEN RAISE EXCEPTION 'El salario debe ser un valor positivo'; END IF;

    -- Validaciones de Longitud
    IF LENGTH(p_nom_cargo) > 100 THEN RAISE EXCEPTION 'El nombre excede los 100 caracteres'; END IF;
    IF LENGTH(p_descripcion_cargo) > 255 THEN RAISE EXCEPTION 'La descripción excede los 255 caracteres'; END IF;

    -- Inserción
    RETURN QUERY
    INSERT INTO tab_cargos (id_cargo, nom_cargo, descripcion_cargo, nivel_riesgo_cargo, salario_base, departamento)
    VALUES (p_id_cargo, TRIM(p_nom_cargo), TRIM(p_descripcion_cargo), TRIM(p_nivel_riesgo_cargo), p_salario_base, TRIM(p_departamento))
    RETURNING tab_cargos.id_cargo, tab_cargos.nom_cargo;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe un cargo con ese ID o Nombre.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar cargo: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Actualizar Cargo
CREATE OR REPLACE FUNCTION fn_tab_cargos_update(
    p_id_cargo INTEGER,
    p_nom_cargo VARCHAR(100),
    p_descripcion_cargo VARCHAR(255),
    p_nivel_riesgo_cargo VARCHAR(50),
    p_salario_base DECIMAL(10,2),
    p_departamento VARCHAR(100)
)
RETURNS TABLE (id_cargo INTEGER, nom_cargo VARCHAR) AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_cargos WHERE tab_cargos.id_cargo = p_id_cargo) THEN
        RAISE EXCEPTION 'El cargo con ID % no existe', p_id_cargo;
    END IF;

    -- Actualización
    RETURN QUERY
    UPDATE tab_cargos
    SET nom_cargo = TRIM(p_nom_cargo),
        descripcion_cargo = TRIM(p_descripcion_cargo),
        nivel_riesgo_cargo = TRIM(p_nivel_riesgo_cargo),
        salario_base = p_salario_base,
        departamento = TRIM(p_departamento)
    WHERE tab_cargos.id_cargo = p_id_cargo
    RETURNING tab_cargos.id_cargo, tab_cargos.nom_cargo;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Ya existe otro cargo con ese nombre.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al actualizar cargo: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Función para Eliminar Cargo
CREATE OR REPLACE FUNCTION fn_tab_cargos_delete(
    p_id_cargo INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_cargos WHERE id_cargo = p_id_cargo) THEN
        RAISE EXCEPTION 'El cargo con ID % no existe', p_id_cargo;
    END IF;

    -- Dependencias
    IF EXISTS (SELECT 1 FROM tab_trabajadores WHERE id_cargo = p_id_cargo) THEN
        RAISE EXCEPTION 'No se puede eliminar el cargo porque tiene trabajadores asociados';
    END IF;

    DELETE FROM tab_cargos WHERE id_cargo = p_id_cargo;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
