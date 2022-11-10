-- PLANTILLA DE ENTREGA DE LA PARTE PRÁCTICA DE LAS ACTIVIDADES
-- --------------------------------------------------------------
-- Actividad: FP.046_PRODUCTO2
--
-- Grupo: Cnv0922_Grupo03: Nínive
-- 
-- Integrantes: 
-- 1. Katiane Coutinho Rosa
-- 2. Miki Alvarez Vidal
-- 3. Daniel Zafra del Pino
-- 4. Daniel Boj Cobos
--
-- Database: ICX0_P3_3
-- --------------------------------------------------------------

USE ICX0_P3_3;

--
-- Pasos previos
--

-- Creación de índices

START TRANSACTION;

ALTER TABLE beneficiario
	ADD UNIQUE INDEX beneficiario_id_socio (id_socio),
    ADD UNIQUE INDEX beneficiario_id_beneficiario (id_beneficiario);

-- Combinaciones Externas

--
-- Ejercicio 1. Mostrar aquellos socios corporativos que no se han inscrito en ninguna actividad. El listado deberá mostrar los siguientes campos: idSocio, Nombre, 
-- Apellido1, Nombre del Plan.
--

START TRANSACTION;

SELECT s.id_socio AS 'ID Socio', s.nombre AS 'Nombre', s.apellido1 AS 'Apellido', (
		SELECT p.plan
		FROM plan p 
		WHERE p.id_plan = s.id_plan) AS 'Nombre del Plan'
	FROM socio s 
    JOIN corporativo c 
    ON (c.id_socio = s.id_socio)
    LEFT JOIN inscripcion i
    ON (i.id_socio = s.id_socio)
    WHERE (s.id_socio NOT IN (
		SELECT id_socio
        FROM inscripcion))
    ORDER BY s.id_socio;

COMMIT;

--
-- Ejercicio 2. Mostrar un listado de socios a los cuales no se les haya registrado cambios desde que se registraron en el gimnasio (no aparecen en la tabla histórico) 
-- ordenados por idPlan y Fecha Alta.
-- El listado deberá mostrar los siguientes campos: idSocio, Nombre, Apellido1, Nombre del Plan.
--

START TRANSACTION;

SELECT s.id_socio AS 'ID Socio', s.nombre AS 'Nombre', s.apellido1 AS 'Apellido', (
		SELECT p.plan
		FROM plan p 
		WHERE p.id_plan = s.id_plan) AS 'Nombre del Plan'
	FROM socio s 
    LEFT JOIN historico h
    ON (h.id_socio = s.id_socio)
    WHERE (s.id_socio NOT IN (
		SELECT id_socio
        FROM historico))
    ORDER BY id_plan, fecha_alta;
    
COMMIT;

--
-- Ejercicio 3. Mostrar un listado de socios no corporativos a los cuales no se les haya realizado ningún seguimiento, ordenado por tipo de socio 
-- (principal y beneficiarios). 
-- El listado deberá mostrar los siguientes campos: idSocio, Nombre, Apellido1, Días de Alta en el Gimnasio.
--

START TRANSACTION;

SELECT sc.id_socio AS 'ID Socio', sc.nombre AS 'Nombre', sc.apellido1 AS 'Apellido', (DATEDIFF(CURDATE(), sc.fecha_alta)) AS 'Días de Alta en el Gimnasio'
	FROM socio sc 
    LEFT JOIN seguimiento sg
    ON (sg.id_socio = sc.id_socio)
    WHERE (sc.id_socio NOT IN (
		SELECT id_socio
        FROM corporativo))
	AND (sc.id_socio NOT IN (
		SELECT id_socio
        FROM seguimiento))
	ORDER BY (
		SELECT IF (s.id_socio IN (b.id_socio), 'Beneficiario', 'Principal') AS 'Tipo'
		FROM socio s
		LEFT JOIN beneficiario b
		ON (b.id_socio = s.id_socio)
        WHERE (s.id_socio = sc.id_socio));
        
COMMIT;

-- Subconsultas

--
-- Ejercicio 4. Mostrar el idSocio, nombre, apellido1, apellido2 y la fecha de alta del socio más antiguo del gimnasio.
--

START TRANSACTION;

SELECT id_socio AS 'ID Socio', CONCAT(nombre, ' ', apellido1, ' ', apellido2) AS 'Nombre', fecha_alta AS 'Fecha de Alta'
	FROM socio
    WHERE fecha_alta = (
		SELECT	MIN(fecha_alta)
			FROM socio);
            
COMMIT;

--
-- Ejercicio 5. Mostrar todos los datos de la Empresa que firmó el último convenio con el gimnasio.
--

SELECT *
	FROM empresa
	WHERE fecha_inicio_convenio = (
		SELECT MAX(fecha_inicio_convenio)
        FROM empresa);

--
-- Ejercicio 6. Mostrar el id, nombre y apellidos de aquellos socios con IMC más bajo que el mejor IMC del socio que esté inscrito en el Plan id=3. 
-- Mostrar en la consulta el mejor IMC.
--

SELECT s.id_socio 'ID Socio', s.nombre AS 'Nombre', CONCAT(s.apellido1, ' ', s.apellido2) AS 'Apellidos', MIN((sg.peso / POWER((sg.estatura_cm / 100), 2))) AS 'Mejor IMC'
	FROM socio s
	JOIN seguimiento sg
	ON (sg.id_socio = s.id_socio)
	WHERE (peso / POWER((estatura_cm / 100), 2)) < (
		SELECT MIN((sgm.peso / POWER((sgm.estatura_cm / 100), 2))) AS IMC
			FROM seguimiento sgm
            JOIN socio sco
            ON (sco.id_socio = sgm.id_socio)
			WHERE (sco.id_plan = 3))
	GROUP BY s.id_socio;

-- Consultas UNION

-- Consultas previas al uso de clásulas UNION

--
-- Ejercico 7. Generar una consulta resumen que tenga como campos los siguientes:
-- NIF (empresa), Nombre Empresa, Teléfono, idPlan, nombre del Plan, Número Afiliados, Cuota Mensual por Afiliado (de la tabla Plan), Importe Total.
--

START TRANSACTION;

SELECT DISTINCT e.nif AS 'NIF', e.empresa AS 'Nombre Empresa', e.telefono AS'Teléfono', s.id_plan AS 'ID Plan', p.plan AS 'Nombre del Plan', (
	SELECT COUNT(cp.id_socio)
		FROM corporativo cp
		INNER JOIN socio sco
		ON (sco.id_socio = cp.id_socio)
		WHERE (nif = e.nif) AND (id_plan = s.id_plan)
		GROUP BY nif, id_plan
		) AS 'Número Afiliados',
	p.cuota_mensual AS 'Cuota Mensual por Afiliado', (
	SELECT SUM(p.cuota_mensual) 
		FROM plan p 
		INNER JOIN socio sc 
        ON (s.id_plan = p.id_plan) 
        INNER JOIN corporativo c 
        ON (sc.id_socio = c.id_socio) 
        WHERE c.nif = e.nif AND sc.id_plan = s.id_plan
        GROUP BY nif, s.id_plan) AS 'Importe Total'
	FROM corporativo c
    JOIN empresa e
    ON(e.nif = c.nif)
    JOIN socio s 
    ON (s.id_socio = c.id_socio)
    JOIN plan p
    ON (p.id_plan = s.id_plan)
    ORDER BY empresa;
    
COMMIT;
    
--
-- Ejercicio 8. Generar otra consulta resumen que tenga como campos los siguientes:
-- Documento Identidad (socio), Nombres y Apellidos del Socio (en una sola columna), Teléfono, idPlan, nombre del Plan, Número Afiliados 
-- (el socio principal + sus beneficiarios), Cuota Mensual  (de la tabla Plan), Importe Total.
--

START TRANSACTION;

SELECT s.documento_identidad AS 'Documento Identidad', CONCAT(s.nombre, ' ', s.apellido1, ' ', s.apellido2) AS 'Nombres y Apellidos del Socio', s.telefono_contacto AS 'Teléfono', 
	s.id_plan AS 'ID Plan', p.plan AS 'Nombre del Plan', IFNULL((
    SELECT COUNT(bf.id_beneficiario)
		FROM beneficiario bf
        WHERE bf.id_socio_principal_referencia = s.id_socio
		GROUP BY bf.id_socio_principal_referencia), 0) AS 'Número de Afiliados', p.cuota_mensual AS 'Cuota Mensual', (
    SELECT IF (s.id_socio NOT IN (SELECT id_socio FROM beneficiario), IFNULL(p.cuota_mensual + (
		SELECT SUM(pl.cuota_mensual - (pl.cuota_mensual * (bf.porcentaje_descuento / 100)))
			FROM plan pl
			JOIN socio sc
			ON (sc.id_plan = pl.id_plan)
			JOIN beneficiario bf
			ON (bf.id_socio = sc.id_socio)
			WHERE s.id_socio = id_socio_principal_referencia
			GROUP BY id_socio_principal_referencia), cuota_mensual), 0)
		FROM socio sco
		JOIN plan p 
		ON(sco.id_plan = p.id_plan)
        WHERE s.id_socio = sco.id_socio
		ORDER by s.id_socio) AS 'Importe Total'
	FROM socio s
    INNER JOIN plan p
    ON (s.id_plan = p.id_plan)
    LEFT JOIN beneficiario b
    ON (s.id_socio = b.id_socio_principal_referencia)
    ORDER BY s.id_socio;
      
COMMIT;

--
-- Ejercico 9. Crea una consulta de UNION con los datos de las dos consultas anteriores.
--

START TRANSACTION;

SELECT DISTINCT e.nif AS 'NIF/DNI', e.empresa AS 'Nombre', e.telefono AS'Teléfono', s.id_plan AS 'ID Plan', p.plan AS 'Nombre del Plan', (
	SELECT COUNT(cp.id_socio)
		FROM corporativo cp
		INNER JOIN socio sco
		ON (sco.id_socio = cp.id_socio)
		WHERE (nif = e.nif) AND (id_plan = s.id_plan)
		GROUP BY nif, id_plan
		) AS 'Número Afiliados',
	p.cuota_mensual AS 'Cuota Mensual por Afiliado', (
	SELECT SUM(p.cuota_mensual) 
		FROM plan p 
		INNER JOIN socio sc 
        ON (s.id_plan = p.id_plan) 
        INNER JOIN corporativo c 
        ON (sc.id_socio = c.id_socio) 
        WHERE c.nif = e.nif AND sc.id_plan = s.id_plan
        GROUP BY nif, s.id_plan) AS 'Importe Total Mensual'
	FROM corporativo c
    JOIN empresa e
    ON(e.nif = c.nif)
    JOIN socio s 
    ON (s.id_socio = c.id_socio)
    JOIN plan p
    ON (p.id_plan = s.id_plan)
    UNION
    SELECT s.documento_identidad, CONCAT(s.nombre, ' ', s.apellido1, ' ', s.apellido2), s.telefono_contacto, 
	s.id_plan, p.plan, IFNULL((
    SELECT COUNT(bf.id_beneficiario)
		FROM beneficiario bf
        WHERE bf.id_socio_principal_referencia = s.id_socio
		GROUP BY bf.id_socio_principal_referencia), 0), p.cuota_mensual, (
    SELECT IF (s.id_socio NOT IN (SELECT id_socio FROM beneficiario), IFNULL(p.cuota_mensual + (
		SELECT SUM(pl.cuota_mensual - (pl.cuota_mensual * (bf.porcentaje_descuento / 100)))
			FROM plan pl
			JOIN socio sc
			ON (sc.id_plan = pl.id_plan)
			JOIN beneficiario bf
			ON (bf.id_socio = sc.id_socio)
			WHERE s.id_socio = id_socio_principal_referencia
			GROUP BY id_socio_principal_referencia), cuota_mensual), 0)
		FROM socio sco
		JOIN plan p 
		ON(sco.id_plan = p.id_plan)
        WHERE s.id_socio = sco.id_socio
		ORDER by s.id_socio) AS 'Importe Total'
	FROM socio s
    INNER JOIN plan p
    ON (s.id_plan = p.id_plan)
    LEFT JOIN beneficiario b
    ON (s.id_socio = b.id_socio_principal_referencia);
    
COMMIT;
--
-- Ejercicio 10. Crea una consulta de UNION que muestre TODAS las actividades del Gimnasio, La consulta deberá tener los siguientes campos:
-- idActividad, Actividad, tipo (Dirigida/Extra), matrícula (si es dirigida mostrar 0, de lo contrario, mostrar el precio de la matrícula), 
-- precio mensual (si es dirigida mostrar 0, de lo contrario, mostrar el precio), porcentaje de descuento abonados (si es dirigida mostrar 0, de lo contrario, mostrar el precio).
--
 
-- Añadimos los registros a las tablas dirigida y extra
    
START TRANSACTION;
    
INSERT INTO dirigida (id_actividad, resistencia, fuerza, velocidad, coordinacion, flexibilidad, equilibrio, agilidad) VALUES
	(1, 1, 0, 0, 1, 1, 1, 1),
	(2, 1, 0, 0, 1, 0, 1, 1),
	(3, 1, 0, 0, 1, 0, 1, 1),
	(4, 1, 1, 0, 1, 0, 1, 0),
	(5, 1, 1, 0, 1, 0, 0, 0),
    (6, 1, 1, 0, 0, 0, 0, 0),
	(7, 1, 0, 0, 0, 0, 0, 0),
	(8, 0, 1, 0, 1, 1, 1, 0),
	(9, 1, 1, 0, 0, 0, 0, 0),
	(10, 0, 1, 0, 0, 0, 0, 0),
    (11, 1, 1, 1, 1, 0, 0, 0),
    (12, 1, 1, 1, 1, 0, 0, 0),
    (13, 1, 1, 1, 1, 0, 0, 0),
    (14, 0, 1, 0, 0, 1, 0, 0),
    (15, 1, 0, 0, 1, 0, 1, 1),
    (16, 0, 0, 0, 1, 1, 0, 0),
    (17, 0, 0, 0, 1, 1, 1, 1),
    (18, 1, 1, 1, 1, 0, 0, 1),
    (19, 1, 1, 1, 1, 1, 0, 0),
    (20, 1, 0, 0, 1, 1, 1, 0),
    (21, 0, 0, 0, 1, 0, 0, 1);
    
COMMIT;
    
START TRANSACTION;
    
INSERT INTO extra (id_Actividad, clases_semanales, matricula, mensualidad, descuento_abonados) VALUES
	(1, 4, 20.00, 15.00, 10),
	(2, 3, 15.00, 10.00, 5),
	(3, 2, 30.00, 20.00, 20),
	(4, 5, 15.00, 10.00, 5),
	(5, 4, 25.00, 15.00, 10),
	(6, 4, 20.00, 15.00, 10),
	(7, 3, 15.00, 10.00, 5),
	(8, 2, 30.00, 20.00, 20),
	(9, 5, 15.00, 10.00, 5),
	(10, 4, 25.00, 15.00, 10),
	(11, 5, 30.00, 20.00, 25),
	(12, 5, 10.00, 5.00, 5),
	(13, 5, 20.00, 10.00, 10),
	(14, 3, 25.00, 15.00, 10),
	(15, 4, 20.00, 10.00, 5),
	(16, 5, 15.00, 10.00, 0),
	(17, 2, 25.00, 15.00, 10),
	(18, 3, 40.00, 30.00, 20),
	(19, 4, 40.00, 30.00, 20),
	(20, 2, 35.00, 20.00, 15);
    
 COMMIT;
 
 START TRANSACTION;
 
SELECT a.id_actividad AS 'ID Actividad', a.actividad AS 'Nombre', 
	IF(a.id_actividad IN (SELECT id_actividad FROM dirigida), 'DIRIGIDA', null) AS 'Tipo', 
    IF(a.id_actividad IN (SELECT id_actividad FROM dirigida), 0, null)  AS 'Matrícula', 
    IF(a.id_actividad IN (SELECT id_actividad FROM dirigida), 0, null) AS 'Precio Mensual', 
    IF(a.id_actividad IN (SELECT id_actividad FROM dirigida), 0, null) AS 'Mensualidad con Porcentaje Descuento Abonados'
    FROM actividad a
    JOIN dirigida d
    ON (d.id_actividad = a.id_actividad)
UNION ALL
SELECT a.id_actividad AS 'ID Actividad', a.actividad AS 'Nombre', 
	IF(a.id_actividad IN (SELECT id_actividad FROM extra), 'EXTRA', null)  AS 'Tipo',  
    IF(a.id_actividad IN (SELECT id_actividad FROM extra), matricula, 0)  AS 'Matrícula', 
    IF(a.id_actividad IN (SELECT id_actividad FROM extra), mensualidad, 0) AS 'Precio Mensual', 
    IF(a.id_actividad IN (SELECT id_actividad FROM extra), (e.mensualidad - (e.mensualidad * (e.descuento_abonados / 100))), 0) AS 'Mensualidad con Porcentaje Descuento Abonados'
    FROM actividad a
    JOIN extra e
    ON (e.id_actividad = a.id_actividad)
    ORDER BY `ID Actividad`;
    
COMMIT;

--
-- Ejercicio 11. Crea una vista a la cual llamarás Base_Facturacion  y que guardará la consulta de UNIÓN del punto 9.
--

START TRANSACTION;

CREATE OR REPLACE VIEW Base_Facturacion
	AS SELECT DISTINCT e.nif AS 'NIF/DNI', e.empresa AS 'Nombre', e.telefono AS'Teléfono', s.id_plan AS 'ID Plan', p.plan AS 'Nombre del Plan', (
		SELECT COUNT(cp.id_socio)
			FROM corporativo cp
			INNER JOIN socio sco
			ON (sco.id_socio = cp.id_socio)
			WHERE (nif = e.nif) AND (id_plan = s.id_plan)
			GROUP BY nif, id_plan
			) AS 'Número Afiliados',
		p.cuota_mensual AS 'Cuota Mensual por Afiliado', (
		SELECT SUM(p.cuota_mensual) 
			FROM plan p 
			INNER JOIN socio sc 
			ON (s.id_plan = p.id_plan) 
			INNER JOIN corporativo c 
			ON (sc.id_socio = c.id_socio) 
			WHERE c.nif = e.nif AND sc.id_plan = s.id_plan
			GROUP BY nif, s.id_plan) AS 'Importe Total Mensual'
		FROM corporativo c
		JOIN empresa e
		ON(e.nif = c.nif)
		JOIN socio s 
		ON (s.id_socio = c.id_socio)
		JOIN plan p
		ON (p.id_plan = s.id_plan)
		UNION
		SELECT s.documento_identidad, CONCAT(s.nombre, ' ', s.apellido1, ' ', s.apellido2), s.telefono_contacto, 
		s.id_plan, p.plan, IFNULL((
		SELECT COUNT(bf.id_beneficiario)
			FROM beneficiario bf
			WHERE bf.id_socio_principal_referencia = s.id_socio
			GROUP BY bf.id_socio_principal_referencia), 0), p.cuota_mensual, (
		SELECT IF (s.id_socio NOT IN (SELECT id_socio FROM beneficiario), IFNULL(p.cuota_mensual + (
			SELECT SUM(pl.cuota_mensual - (pl.cuota_mensual * (bf.porcentaje_descuento / 100)))
				FROM plan pl
				JOIN socio sc
				ON (sc.id_plan = pl.id_plan)
				JOIN beneficiario bf
				ON (bf.id_socio = sc.id_socio)
				WHERE s.id_socio = id_socio_principal_referencia
				GROUP BY id_socio_principal_referencia), cuota_mensual), 0)
			FROM socio sco
			JOIN plan p 
			ON(sco.id_plan = p.id_plan)
			WHERE s.id_socio = sco.id_socio
			ORDER by s.id_socio) AS 'Importe Total'
		FROM socio s
		INNER JOIN plan p
		ON (s.id_plan = p.id_plan)
		LEFT JOIN beneficiario b
		ON (s.id_socio = b.id_socio_principal_referencia);
    
COMMIT;
 
 -- Comprobamos
 
select * FROM Base_facturacion;

--
-- Ejercicio 12. Crea una vista a la cual llamarás Actividades_Gym  y que guardará la consulta de UNIÓN del punto 10.
--

START TRANSACTION;

CREATE OR REPLACE VIEW Actividades_Gym
	AS SELECT a.id_actividad, a.actividad, 
		IF(a.id_actividad IN (SELECT id_actividad FROM dirigida), 'DIRIGIDA', null) AS 'Tipo', 
		IF(a.id_actividad IN (SELECT id_actividad FROM dirigida), 0, null)  AS 'Matrícula', 
		IF(a.id_actividad IN (SELECT id_actividad FROM dirigida), 0, null) AS 'Precio Mensual', 
		IF(a.id_actividad IN (SELECT id_actividad FROM dirigida), 0, null) AS 'Mensualidad con Porcentaje Descuento Abonados'
		FROM actividad a
		JOIN dirigida d
		ON (d.id_actividad = a.id_actividad)
	UNION ALL
	SELECT a.id_actividad, a.actividad, 
		IF(a.id_actividad IN (SELECT id_actividad FROM extra), 'EXTRA', null)  AS 'Tipo',  
		IF(a.id_actividad IN (SELECT id_actividad FROM extra), matricula, 0)  AS 'Matrícula', 
		IF(a.id_actividad IN (SELECT id_actividad FROM extra), mensualidad, 0) AS 'Precio Mensual', 
		IF(a.id_actividad IN (SELECT id_actividad FROM extra), (e.mensualidad - (e.mensualidad * (e.descuento_abonados / 100))), 0) AS 'Mensualidad con Porcentaje Descuento Abonados'
		FROM actividad a
		JOIN extra e
		ON (e.id_actividad = a.id_actividad)
		ORDER BY id_actividad;

COMMIT;

-- Comprobamos

SELECT * FROM Actividades_Gym;

--
-- Ejercicio 13. Crea una vista a la cual llamarás Socios_Planes que guardará los siguientes campos: idPlan, Nombre Plan, Total_Socios.
--

START TRANSACTION;

CREATE OR REPLACE VIEW Socios_Planes AS
	SELECT s.id_plan AS 'ID Plan', p.plan AS 'Nombre Plan', COUNT(s.id_socio) AS 'Total Socios'
		FROM socio s
		JOIN plan p
		ON (p.id_plan = s.id_plan)
		GROUP BY s.id_plan
		ORDER BY s.id_plan;

COMMIT;

-- Comprobamos

SELECT * FROM Socios_Planes;

--
-- Ejercicio 14. Crea una vista a la cual llamarás Socios_Totales que guardará el número total de socios del gimnasio.
--

START TRANSACTION;

CREATE OR REPLACE VIEW Socios_Totales AS
	SELECT COUNT(id_socio) AS 'Socios Totales del Gimnasio'
	FROM socio;

COMMIT;

-- Comprobamos

SELECT * FROM Socios_Totales;

--
-- Ejercicio 15. Haciendo uso de las dos vistas anteriores, crea una consulta que muestre el % de socios de cada plan respecto de 
-- los socios totales del gimnasio, ordenada por el porcentaje calculado de mayor a menor.
--

START TRANSACTION;

SELECT *, ROUND((sp.`Total Socios` / (SELECT * FROM Socios_Totales)) * 100) AS 'Porcentaje de Socios'
	FROM Socios_Planes sp
	ORDER BY `Porcentaje de Socios` DESC;

COMMIT;