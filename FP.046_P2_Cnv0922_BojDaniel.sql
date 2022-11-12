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

/* Los necesitaremos para agilizar y evitar duplicados */

-- Combinaciones Externas

--
-- Ejercicio 1. Mostrar aquellos socios corporativos que no se han inscrito en --ninguna actividad. El listado deberá mostrar los siguientes campos: idSocio, --Nombre, Apellido1, Nombre del Plan.
--

SELECT s.id_socio AS 'ID Socio', s.nombre AS 'Nombre', s.apellido1 AS 'Apellido', p.plan AS 'Nombre del Plan'
	FROM socio s 
    JOIN corporativo c 
    ON (c.id_socio = s.id_socio)
    LEFT JOIN inscripcion i
    ON (i.id_socio = s.id_socio)
	INNER JOIN plan p 
	ON (p.id_plan=s.id_plan)
    WHERE i.id_socio IS NULL
    ORDER BY s.id_socio;

--
-- Ejercicio 2. Mostrar un listado de socios a los cuales no se les haya --registrado cambios desde que se registraron en el gimnasio (no aparecen en la --tabla histórico) ordenados por idPlan y Fecha Alta.
-- El listado deberá mostrar los siguientes campos: idSocio, Nombre, Apellido1, --Nombre del Plan.
--


SELECT s.id_socio AS 'ID Socio', s.nombre AS 'Nombre', s.apellido1 AS 'Apellido', p.id_plan AS 'Nombre del Plan'
	FROM socio s 
    LEFT JOIN historico h
    	ON (h.id_socio = s.id_socio)
	INNER JOIN plan p 
		ON (p.id_plan = s.id_plan)
    WHERE h.id_socio IS NULL;
    ORDER BY id_plan, fecha_alta;

--
-- Ejercicio 3. Mostrar un listado de socios no corporativos a los cuales no se --les haya realizado ningún seguimiento, ordenado por tipo de socio 
-- (principal y beneficiarios). 
-- El listado deberá mostrar los siguientes campos: idSocio, Nombre, Apellido1, --Días de Alta en el Gimnasio.
--

SELECT sc.id_socio AS 'ID Socio', sc.nombre AS 'Nombre', sc.apellido1 AS 'Apellido', 
	IF (sc.activo = 1, (DATEDIFF(CURDATE(), sc.fecha_alta)), DATEDIFF(h.fecha_cambio, sc.fecha_alta)) AS 'Días de Alta en el Gimnasio'
	FROM socio sc 
    INNER JOIN plan p 
		ON (p.id_plan = sc.id_plan)
    LEFT JOIN seguimiento sg
		ON (sg.id_socio = sc.id_socio)
	LEFT JOIN historico h 
		ON (h.id_socio = sc.id_socio)
	WHERE p.tipo = 'P' AND sg.id_socio IS NULL
	ORDER BY  (
		SELECT IF (s.id_socio IN (b.id_socio), 'Beneficiario', 'Principal')
		FROM socio s
		LEFT JOIN beneficiario b
		ON (b.id_socio = s.id_socio)
        WHERE (s.id_socio = sc.id_socio)) DESC, sc.id_socio;

-- Subconsultas

--
-- Ejercicio 4. Mostrar el idSocio, nombre, apellido1, apellido2 y la fecha de --alta del socio más antiguo del gimnasio.
--

START TRANSACTION;

SELECT id_socio AS 'ID Socio', CONCAT(nombre, ' ', apellido1, ' ', apellido2) AS 'Nombre', fecha_alta AS 'Fecha de Alta'
	FROM socio
    WHERE fecha_alta = (
		SELECT	MIN(fecha_alta)
			FROM socio);
            
/* Debemos unar una SUBCONSULTA dentro de la cláusula WHERE para establecer una condición que compare la fecha de alta de cada socio con la fecha de alta menor de la tabla socio, para ello usaremos la funcion MIN() sobre la columna fecha de alta. De este modo, la consulta nos devuelve una única fila, la más antigua. */

COMMIT;

--
-- Ejercicio 5. Mostrar todos los datos de la Empresa que firmó el último --convenio con el gimnasio.
--

START TRANSACTION;

SELECT *
	FROM empresa
	WHERE fecha_inicio_convenio = (
		SELECT MAX(fecha_inicio_convenio)
        FROM empresa);
/* Deberemos unas una SUBCONSULTA a la izquierda de la comparación de la cláusula WHERE que compare las fechas de inicio de convenio de cada empresa con la fecha del convenio más reciente que obtenemos aplicando la función MAX() a la columna fecha_inicio_convenio */

COMMIT;

--
-- Ejercicio 6. Mostrar el id, nombre y apellidos de aquellos socios con IMC --más bajo que el mejor IMC del socio que esté inscrito en el Plan id=3. 
-- Mostrar en la consulta el mejor IMC.
--

-- ¡Muy importante!: EL IMC NO ES EL ÍNDICE DE GRASA CORPORAL, EL IMC SE --CALCULA CON LA SIGUIENTE FÓRMULA: peso en kg / (estatura en m al cuadrado)

START TRANSACTION;

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
/* Para realizar este ejercicio debemos usar JOIN, SUBCONSULTAS y funciones:
1. Seleccionamos el menor IMC de los usuarios mediante la función MIN() en la que seleccionaremos las columnas peso y estatura_cm para realizar el cálculo del IMC.
2. Usamos "socio" como tabla principal para obtener los datos: id_socio, nombre y apellidos, peso y estatura.
3. Usamos un INNER JOIN con la tabla "seguimiento" para filtrar únicamente a los socios que tengan un seguimiento realizado.
4. Usamos un filtrado del retorno mediante WHERE donde, a la izquierda de la comparación colocamos el IMC del usuario actualmente consultado y a la derecha una SUBCONSULTA que nos devuelve el mejor IMC de los usuarios en el plan 3.
5. Para esta SUBCONSULTA obtenemos el IMC como columna virtual que devolveremos y filtramos, mediante un JOIN para unir los datos de la tabla principal "socio" con la tabla hija "seguimiento" y mediante la cláusula WHERE para limitarlo a usuarios del plan 3. Mediante la función MIN() obtendremos únicamente el mejor IMC. */

COMMIT;

-- Consultas UNION

-- Consultas previas al uso de clásulas UNION

--
-- Ejercico 7. Generar una consulta resumen que tenga como campos los --siguientes:
-- NIF (empresa), Nombre Empresa, Teléfono, idPlan, nombre del Plan, Número --Afiliados, Cuota Mensual por Afiliado (de la tabla Plan), Importe Total.
--

SELECT e.nif As 'NIF', e.empresa AS 'Nombre Empresa', e.telefono AS 'Teléfono', s.id_plan AS 'ID Plan', p.plan As 'Nombre Plan', 
	COUNT(s.id_socio) AS "Numero Afiliados", p.cuota_mensual, (COUNT(s.id_socio) * p.cuota_mensual) AS "Importe Total" 
	FROM empresa e
	LEFT JOIN corporativo sc
		ON sc.nif = e.nif
	LEFT JOIN socio s
		ON s.id_socio = sc.id_socio
	LEFT JOIN plan p
		ON s.id_plan = p.id_plan
	GROUP BY e.nif, p.id_plan;
    
--
-- Ejercicio 8. Generar otra consulta resumen que tenga como campos los --siguientes:
-- Documento Identidad (socio), Nombres y Apellidos del Socio (en una sola --columna), Teléfono, idPlan, nombre del Plan, Número Afiliados 
-- (el socio principal + sus beneficiarios), Cuota Mensual  (de la tabla Plan), --Importe Total.
--

	SELECT s.documento_identidad AS 'Documento Identidad', CONCAT(s.nombre, ' ', s.	apellido1, ' ', s.apellido2) AS 'Nombres y Apellidos del Socio', s.telefono_contacto AS 'Teléfono', s.id_plan AS 'ID Plan', p.plan AS 'Nombre del Plan', IFNULL((
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

--
-- Ejercico 9. Crea una consulta de UNION con los datos de las dos consultas anteriores.
--

SELECT e.nif AS 'NIF/DNI', e.empresa AS 'Nombre', e.telefono As 'Teléfono', s.id_plan As 'ID Plan', plan AS 'Nombre del Plan', 
COUNT(s.id_socio) AS "Numero Afiliados", p.cuota_mensual AS 'Cuota Mensual por Afiliado', ( COUNT(s.id_socio) * p.cuota_mensual ) AS "Importe Total" 
	FROM empresa e
	LEFT JOIN corporativo sc
		ON sc.nif = e.nif
	LEFT JOIN socio s
		ON s.id_socio = sc.id_socio
	LEFT JOIN plan p
		ON s.id_plan = p.id_plan
	GROUP BY e.nif, p.id_plan	
UNION
SELECT s.documento_identidad, CONCAT_WS(' ', s.nombre, s.apellido1, s.apellido2), s.telefono_contacto, s.id_plan, p.plan, IFNULL((
    SELECT COUNT(bf.id_beneficiario) + 1
		FROM beneficiario bf
        WHERE bf.id_socio_principal_referencia = s.id_socio
		GROUP BY bf.id_socio_principal_referencia), IF (s.id_socio IN (SELECT id_socio FROM beneficiario), 0, 1)), p.cuota_mensual, (
    SELECT IF (s.id_socio NOT IN (SELECT id_socio FROM beneficiario) AND s.id_socio NOT IN (SELECT id_socio FROM corporativo), IFNULL(p.cuota_mensual + (
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
		ORDER by s.id_socio)
	FROM socio s
    INNER JOIN plan p
		ON (s.id_plan = p.id_plan)
    LEFT JOIN beneficiario b
		ON (s.id_socio = b.id_socio_principal_referencia)
	GROUP BY s.id_socio;
    
--
-- Ejercicio 10. Crea una consulta de UNION que muestre TODAS las actividades del Gimnasio, La consulta deberá tener los siguientes campos:
-- idActividad, Actividad, tipo (Dirigida/Extra), matrícula (si es dirigida mostrar 0, de lo contrario, mostrar el precio de la matrícula), 
-- precio mensual (si es dirigida mostrar 0, de lo contrario, mostrar el precio), porcentaje de descuento abonados (si es dirigida mostrar 0, de lo contrario, mostrar el precio).
--
 
-- Añadimos los registros a las tablas dirigida y extra para que la consulta dé --resultados
    
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

--
-- Ejercicio 11. Crea una vista a la cual llamarás Base_Facturacion  y que guardará la consulta de UNIÓN del punto 9.
--

CREATE OR REPLACE VIEW Base_Facturacion
	AS SELECT e.nif AS 'NIF/DNI', e.empresa AS 'Nombre', e.telefono As 'Teléfono', s.id_plan As 'ID Plan', plan AS 'Nombre del Plan', 
COUNT(s.id_socio) AS "Numero Afiliados", p.cuota_mensual AS 'Cuota Mensual por Afiliado', ( COUNT(s.id_socio) * p.cuota_mensual ) AS "Importe Total" 
	FROM empresa e
	LEFT JOIN corporativo sc
		ON sc.nif = e.nif
	LEFT JOIN socio s
		ON s.id_socio = sc.id_socio
	LEFT JOIN plan p
		ON s.id_plan = p.id_plan
	GROUP BY e.nif, p.id_plan	
UNION
SELECT s.documento_identidad, CONCAT_WS(' ', s.nombre, s.apellido1, s.apellido2), s.telefono_contacto, s.id_plan, p.plan, IFNULL((
    SELECT COUNT(bf.id_beneficiario) + 1
		FROM beneficiario bf
        WHERE bf.id_socio_principal_referencia = s.id_socio
		GROUP BY bf.id_socio_principal_referencia), IF (s.id_socio IN (SELECT id_socio FROM beneficiario), 0, 1)), p.cuota_mensual, (
    SELECT IF (s.id_socio NOT IN (SELECT id_socio FROM beneficiario) AND s.id_socio NOT IN (SELECT id_socio FROM corporativo), IFNULL(p.cuota_mensual + (
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
		ORDER by s.id_socio)
	FROM socio s
    INNER JOIN plan p
		ON (s.id_plan = p.id_plan)
    LEFT JOIN beneficiario b
		ON (s.id_socio = b.id_socio_principal_referencia)
	GROUP BY s.id_socio;
 
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

CREATE OR REPLACE VIEW Socios_Planes AS
	SELECT s.id_plan AS 'ID Plan', p.plan AS 'Nombre Plan', COUNT(s.id_socio) AS 'Total Socios'
		FROM socio s
		RIGHT JOIN plan p
			ON (p.id_plan = s.id_plan)
		GROUP BY s.id_plan
		ORDER BY s.id_plan;

-- Comprobamos

SELECT * FROM Socios_Planes;

--
-- Ejercicio 14. Crea una vista a la cual llamarás Socios_Totales que guardará el número total de socios del gimnasio.
--

CREATE OR REPLACE VIEW Socios_Totales AS
	SELECT COUNT(id_socio) AS 'Socios Totales del Gimnasio'
	FROM socio;


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