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

-- Consultas Externas

--
-- Pregunta 1
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
-- Pregunta 2
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
-- Pregunta 3
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
-- Ejercicio 4
--

START TRANSACTION;

SELECT id_socio AS 'ID Socio', nombre AS 'Nombre', CONCAT(apellido1, ' ', apellido2) AS Apellidos, fecha_alta AS 'FEcha de Alta'
	FROM socio
    WHERE fecha_alta = (
		SELECT	MIN(fecha_alta)
			FROM socio);
            
COMMIT;

--
-- Ejercicio 5
--

START TRANSACTION;

SELECT *
	FROM empresa
	WHERE fecha_inicio_convenio = (
		SELECT MAX(fecha_inicio_convenio)
        FROM empresa);

COMMIT;

--
-- Ejercicio 6
--

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

COMMIT;
