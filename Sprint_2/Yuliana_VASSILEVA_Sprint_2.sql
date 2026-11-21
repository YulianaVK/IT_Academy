			-- ============================================================
					-- SPRINT 2 — SQL
			-- Especialització Data Analytics — IT Academy \ CIBERNÀRIUM
			-- ============================================================

-- ====================================================================
-- BLOC 0: PREPARACIÓ — Nou usuari i permisos per separar bbdd de FADD
-- ====================================================================

CREATE USER 'Especial_DA'@'localhost' IDENTIFIED BY '******_**-**';
FLUSH PRIVILEGES;

SELECT user, host FROM mysql.user WHERE user = 'Especial_DA';

-- Pemiso de acceso a la bbdd creada, cargando los 2 primeros sql (+ 1 tabla adicional para cargar datos del 3º sql
GRANT ALL PRIVILEGES ON `transactions`.* TO 'Especial_DA'@'localhost';
FLUSH PRIVILEGES;

			-- ======== Nivell 1 ========

-- ============================================================
-- N1 · Ex.1: Recompte de registres
-- ============================================================
USE transactions;

SELECT COUNT(*) FROM company;
-- Recuento registros tabla
SELECT COUNT(*) FROM transaction;
-- ============================================================
-- N1 · Ex.2: (apartats a, b, c)
-- ============================================================
USE transactions;

-- a. Lista de países que generan ventas
SELECT DISTINCT c.country AS pais_ventas
FROM transaction AS t
INNER JOIN company AS c ON t.company_id=c.id
ORDER BY pais_ventas;

-- b. Desde cuántos países se generan las ventas.
SELECT COUNT(DISTINCT c.country) AS paises_con_ventas
FROM transaction AS t
INNER JOIN company AS c ON t.company_id=c.id;

-- c. Identifica la empresa con el promedio de ventas más alto
SELECT 
    ROUND(AVG(t.amount),2) AS mayor_promedio_ventas,
    c.company_name AS empresa
FROM
    transaction AS t
        INNER JOIN
    company AS c ON t.company_id = c.id
GROUP BY c.company_name
ORDER BY mayor_promedio_ventas DESC
LIMIT 1;

-- ============================================================
-- N1 · Ex.3: Utilitzar només subconsultas (ssense JOIN) — apartats a, b, c
-- ============================================================:
USE transactions;

-- a. Mostrar todas las transacciones realizadas por empresas en Alemania.
SELECT 
    COUNT(*) AS transacciones_alemania
FROM transaction
	WHERE company_id IN (
		SELECT id
        FROM company
			WHERE country = 'Germany'
		)
;

-- b. Enumera las empresas que han realizado transacciones por importe (amount) superior a la media de todas las transacciones.
SELECT DISTINCT company_name AS con_transacciones_sobre_promedio
FROM company
	WHERE id IN (
		SELECT company_id 
		FROM transaction
			WHERE amount > (
				SELECT AVG(amount)
				FROM transaction)
	)
ORDER BY con_transacciones_sobre_promedio
;

-- c.	Eliminarán del sistema las empresas que no tengan transacciones registradas, entrega la lista de estas empresas.
SELECT DISTINCT company_name AS empresas_sin_transacciones
FROM company
	WHERE id NOT IN (
		SELECT company_id 
		FROM transaction
	)
;
-- ============================================================
-- N1 · Ex.4: Creació i càrrega de la taula credit_card
-- ============================================================
USE transactions;						-- 6 columnas: id, iban, pan, pin, cvv, expiring_date (¡¡Ojo formato!!)

DROP TABLE IF EXISTS credit_card;		-- limpieza preventiva
DROP TABLE IF EXISTS credit_card_raw;	-- también, si reaparece en algún retry

CREATE TABLE credit_card_raw (
    id VARCHAR(20) PRIMARY KEY,
    iban VARCHAR(40),
    pan VARCHAR(25),
    pin VARCHAR(4),
    cvv VARCHAR(3),
    expiring_date VARCHAR(10)  			-- Paso intermedio para fecha en bruto (formato origen mm/dd/aa)
);

CREATE TABLE credit_card (
    id VARCHAR(20) PRIMARY KEY,
    iban VARCHAR(40),
    pan VARCHAR(25),
    pin VARCHAR(4),
    cvv VARCHAR(3),
    expiring_date DATE					-- Tabla definitiva para fecha real (con STR_TO_DATE trás subir sql a la raw)
);

DESCRIBE credit_card_raw;
DESCRIBE credit_card;					-- doble check ambas tablas

-- Inserció de dades: N1-Ex.4__datos_introducir_credit.sql (fitxer facilitat pel professor)

SELECT COUNT(*) FROM credit_card_raw;								-- comprobación tabla intermedia

	-- Traspaso a tabla definitiva corrigiendo fecha para que pueda ir como date
INSERT INTO credit_card (id, iban, pan, pin, cvv, expiring_date)
SELECT id, iban, pan, pin, cvv,                  					--  5 quedan igual
       STR_TO_DATE(expiring_date, '%m/%d/%y')    					-- la 6ª que pasa corregida
FROM credit_card_raw;

SELECT * FROM transactions.credit_card;								-- comprobación formato fecha

SELECT COUNT(*) FROM credit_card;									-- Y recuento de registros

DROP TABLE credit_card_raw;											-- Eliminación de tabla intermedia, accesoria para corregir formato "date"

	-- Ahora sí, declaración FK.   Y ya que la query funciona, no hay transacciones huérfanas no revisadas previamente
ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_credit_card
FOREIGN KEY (credit_card_id)
REFERENCES credit_card(id);
-- ============================================================
-- N1 · Ex.5: Modificació de registres (UPDATE)
-- ============================================================
USE transactions;

SELECT *									-- Localitzo registre erroni
FROM credit_card
WHERE id='CcU-2938';

UPDATE credit_card							-- Modifico la dada (iban)
SET iban = 'TR323456312213576817699999'
WHERE id='CcU-2938';

SELECT *									-- Torno a visualitzar el registre, encara que a l'output avisa d'una fila i un canvi
FROM credit_card
WHERE id='CcU-2938';
-- ============================================================
-- N1_Ex6: INSERT amb creació prèvia de FKs
-- ============================================================
USE transactions;

-- 1º comprovació de camps i registres de les 2 taules relacionades amb les FK que figuren al registre nou que cal introduir
DESCRIBE company;
DESCRIBE credit_card;

-- Després busquem les FK que porta el registre
SELECT * FROM credit_card
WHERE id='CcU-9999';

SELECT * FROM company
WHERE id='b-9999';

-- 1. Creació previa - empresa nova per la PK/FK necessària
INSERT INTO company (id, company_name, phone, email, country, website)
VALUES ('b-9999', 'AD 6e Exercici', '01 234 567 890', 'exercici6@sprint2.com', 'Spain', 'https://sprint2.com');

-- 2. Creació previa - targeta nova per a la PK/FK necessària
INSERT INTO credit_card (id, iban, pan, pin, cvv, expiring_date)
VALUES ('CcU-9999', 'XX36631234567887654321', '1785243310121416', '0190', '060', '2026-11-20');

-- 3. Finalment, creació del registre de la transacció
INSERT INTO transaction (id, credit_card_id, company_id, user_id, lat, longitude, amount, declined)
VALUES ('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', '9999', 829.999, -117.999, 111.11, False);

-- 4. Verificació final
SELECT * FROM transaction WHERE id = '108B1D1D-5B23-A76C-55EF-C568E49A99DD';
-- ============================================================
-- N1 · Ex.7: Eliminació de columna i dades
-- ============================================================
USE transactions;

	-- Nota: es pot fer còpia de 'pan' a una taula de suport, juntament amb 'id', abans de l'eliminació, però com que l'exercici no ho demana, procedeixo directament al DROP.
DESCRIBE credit_card;

ALTER TABLE credit_card DROP COLUMN pan;

DESCRIBE credit_card;
-- ============================================================
-- N1 · Ex.8: Base de dades buyers_club des de zero (esquema estrella)
-- ============================================================
		-- === Crear una bbdd amb les seves taules ===
CREATE DATABASE buyers_club;

USE buyers_club;

CREATE TABLE american_users (
    id INT NOT NULL,
    name VARCHAR(20) NOT NULL,
    surname VARCHAR(35) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(35) NOT NULL,
    birth_date VARCHAR(15),					-- data cruda del CSV; la neteja (STR_TO_DATE) passa al volcar a 'customers'
    country VARCHAR(20) NOT NULL,
    city VARCHAR(20) NOT NULL,
    postal_code VARCHAR(13) NOT NULL,
    address VARCHAR(50) NOT NULL,
    signup_date DATE NOT NULL,
    user_segment VARCHAR(20) NOT NULL,
    income_band VARCHAR(10) NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE european_users (
    id INT NOT NULL,
    name VARCHAR(20) NOT NULL,
    surname VARCHAR(35) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(35) NOT NULL,
    birth_date VARCHAR(15),					-- data cruda del CSV; la neteja (STR_TO_DATE) passa al volcar a 'customers'
    country VARCHAR(20) NOT NULL,
    city VARCHAR(20) NOT NULL,
    postal_code VARCHAR(13) NOT NULL,
    address VARCHAR(50) NOT NULL,
    signup_date DATE NOT NULL,
    user_segment VARCHAR(20) NOT NULL,
    income_band VARCHAR(10) NOT NULL,
    PRIMARY KEY (id)
);
CREATE TABLE customers (
    customer_id INT NOT NULL,
    first_name VARCHAR(20) NOT NULL,
    surname VARCHAR(35) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(35) NOT NULL,
    birth_date DATE,							-- data neta: ve del STR_TO_DATE de les dues taules raw
    country VARCHAR(20) NOT NULL,
    city VARCHAR(20) NOT NULL,
    postal_code VARCHAR(13) NOT NULL,
    address VARCHAR(50) NOT NULL,
	region VARCHAR(15) NOT NULL,				-- dividir entre North America i Europe
    signup_date DATE NOT NULL,
    user_segment VARCHAR(20) NOT NULL,
    income_band VARCHAR(10) NOT NULL,
    PRIMARY KEY (customer_id)
);

CREATE TABLE companies (
	company_id VARCHAR(10) NOT NULL,
    company_name VARCHAR(40) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(35) NOT NULL,
    country VARCHAR(20) NOT NULL,
    website VARCHAR(60) NOT NULL,
    merchant_category VARCHAR(20) NOT NULL,
    merchant_price_position VARCHAR(15) NOT NULL,
    PRIMARY KEY (company_id)
);

CREATE TABLE credit_cards_raw (
    cc_id VARCHAR(20) NOT NULL,
    user_id INT NOT NULL,
	iban VARCHAR(40) NOT NULL,
	pan VARCHAR(25) NOT NULL,
	pin VARCHAR(4) NOT NULL,
    cvv VARCHAR(3) DEFAULT NULL,
    track1 VARCHAR(50),
    track2 VARCHAR(50),
	expiring_date VARCHAR(10) NOT NULL,			-- data crua del CSV; la neteja (STR_TO_DATE) passa al volcar a 'credit_cards'
    card_type VARCHAR(15) NOT NULL,
    card_renewal_flag BOOL NOT NULL,
    PRIMARY KEY (cc_id)
);

CREATE TABLE credit_cards (
    cc_id VARCHAR(20) NOT NULL,
    user_id INT NOT NULL,
	iban VARCHAR(40) NOT NULL,
	pan VARCHAR(25) NOT NULL,
	pin VARCHAR(4) NOT NULL,
    cvv VARCHAR(3) DEFAULT NULL,
    track1 VARCHAR(50),
    track2 VARCHAR(50),
	expiring_date DATE NOT NULL,				-- data neta: ve del STR_TO_DATE de la taula raw corresponent
    card_type VARCHAR(15) NOT NULL,
    card_renewal_flag BOOL NOT NULL,
    PRIMARY KEY (cc_id)
);

CREATE TABLE transactions (
	transaction_id VARCHAR(40) NOT NULL,
	card_id VARCHAR(20) NOT NULL,
    business_id VARCHAR(8) NOT NULL,
    transaction_date TIMESTAMP,
    amount DECIMAL(10,2),
    declined BOOLEAN NOT NULL,
    product_ids VARCHAR(25),
    user_id INT NOT NULL,
    lat DOUBLE,
    longitude DOUBLE,
    discount_amount DECIMAL(10,2) NOT NULL,
    tax_amount DECIMAL(10,2) NOT NULL,
    shipping_amount DECIMAL(10,2) NOT NULL,
    sales_channel VARCHAR(15) NOT NULL,
    campaign_id VARCHAR(20) NOT NULL,
    device_type VARCHAR(10),
    is_international BOOLEAN NOT NULL,
    decline_reason VARCHAR(20),
    distance_km DECIMAL(10,2),
    PRIMARY KEY (transaction_id)
);

		-- === LOADs ===
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IT_Academy/N1-Ex.8__american_users.csv'
INTO TABLE american_users
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, name, surname, phone, email, birth_date, country, city, postal_code, address, signup_date, user_segment, income_band);

		-- = Comprovar de quina carpeta carrega fitxer Workbench =
SHOW VARIABLES LIKE 'secure_file_priv';
-- secure_file_priv	C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\

ALTER TABLE american_users						-- ampliació extensió camps que donen error
    MODIFY email VARCHAR(60),
    MODIFY address VARCHAR(80),
    MODIFY surname VARCHAR(45);

	-- = Check registres a american_users perquè veig  1010 registres, però els id arriben fins a 4999  =
SELECT COUNT(*) FROM american_users;     		 -- 1010
SELECT MIN(id), MAX(id) FROM american_users; 	 -- comença en 1 i arriba a 4999 => hi ha forats i esl numeros no son consecutius
SELECT * FROM american_users ORDER BY id LIMIT 5;
SELECT * FROM american_users ORDER BY id DESC LIMIT 5;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IT_Academy/N1-Ex.8__european_users.csv'
INTO TABLE european_users
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, name, surname, phone, email, birth_date, country, city, postal_code, address, signup_date, user_segment, income_band);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IT_Academy/N1-Ex.8__credit_cards.csv'
INTO TABLE credit_cards_raw
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(cc_id, user_id, iban, pan, pin, cvv, track1, track2, expiring_date, card_type, card_renewal_flag);

ALTER TABLE credit_cards_raw		-- extensió camps track1 i track2
    MODIFY track1 VARCHAR(80),
    MODIFY track2 VARCHAR(80);

		-- = Bolcat dades de taula raw per, corregint format dates =
INSERT INTO customers (customer_id, first_name, surname, phone, email, birth_date, country, city, postal_code, address, region, signup_date, user_segment, income_band)
SELECT id, name, surname, phone, email,
       STR_TO_DATE(birth_date, '%b %d, %Y'),
       country, city, postal_code, address,
       'North_America',
       signup_date, user_segment, income_band
FROM american_users;

ALTER TABLE customers				-- mateixa extensio de columna email q amb american_users
    MODIFY email VARCHAR(60),
    MODIFY address VARCHAR(80),
    MODIFY surname VARCHAR(45);

		-- = Bolcat dades de taula raw, corregint format dates =
INSERT INTO customers (customer_id, first_name, surname, phone, email, birth_date, country, city, postal_code, address, region, signup_date, user_segment, income_band)
SELECT id, name, surname, phone, email,
       STR_TO_DATE(birth_date, '%b %d, %Y'),
       country, city, postal_code, address,
       'Europe',
       signup_date, user_segment, income_band
FROM european_users;

		-- === Checks ===
SELECT COUNT(*) FROM customers;                          -- 50000
SELECT region, COUNT(*) FROM customers GROUP BY region;  -- North_America 1010 / Europe 3990
SELECT * FROM customers LIMIT 3;

-- = Bolcat a credit_cards, corregint format dates =
INSERT INTO credit_cards (cc_id, user_id, iban, pan, pin, cvv, track1, track2, expiring_date, card_type, card_renewal_flag)
SELECT cc_id, user_id, iban, pan, pin, cvv, track1, track2,
       STR_TO_DATE(expiring_date, '%m/%d/%y'),
       card_type, card_renewal_flag
FROM credit_cards_raw;

ALTER TABLE credit_cards		-- extensió camps track1 i track2, igual que a _raw
    MODIFY track1 VARCHAR(80),
    MODIFY track2 VARCHAR(80);

		-- = Check format dates =
SELECT cc_id, expiring_date FROM credit_cards LIMIT 5;

	-- 2 carregues finals ...
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IT_Academy/N1-Ex.8__companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(company_id, company_name, phone, email, country, website, merchant_category, merchant_price_position);

ALTER TABLE companies			-- ajust extensió columna email i després tornar a carregar companies
    MODIFY email VARCHAR(60);

	-- Carrega final, acabant sempre amb la fact table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IT_Academy/N1-Ex.8__transactions.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ';'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(transaction_id, card_id, business_id, transaction_date, amount, declined, product_ids, user_id, lat, longitude, discount_amount, tax_amount, shipping_amount, sales_channel, campaign_id, device_type, is_international, decline_reason, distance_km);

		-- === 4 checks d'orfes ===

-- Transaccions sense targeta
SELECT COUNT(*) FROM transactions t
LEFT JOIN credit_cards c ON t.card_id = c.cc_id
WHERE c.cc_id IS NULL;

-- Transaccions sense empresa
SELECT COUNT(*) FROM transactions t
LEFT JOIN companies co ON t.business_id = co.company_id
WHERE co.company_id IS NULL;

-- Check regional: targetes sense user
SELECT COUNT(*) FROM credit_cards c
LEFT JOIN customers cu ON c.user_id = cu.customer_id
WHERE cu.customer_id IS NULL;

-- Transaccions sense client
SELECT COUNT(*) FROM transactions t
LEFT JOIN customers c ON t.user_id = c.customer_id
WHERE c.customer_id IS NULL;

		-- === Declarar FKs ===
ALTER TABLE transactions
    ADD CONSTRAINT fk_transactions_card
    FOREIGN KEY (card_id) REFERENCES credit_cards(cc_id);

ALTER TABLE transactions
    ADD CONSTRAINT fk_transactions_company
    FOREIGN KEY (business_id) REFERENCES companies(company_id);

ALTER TABLE transactions
    ADD CONSTRAINT fk_transactions_customer
    FOREIGN KEY (user_id) REFERENCES customers(customer_id);

-- Neteja 3 taules de pas (2 per customers i 1 raw)
DROP TABLE IF EXISTS american_users, european_users, credit_cards_raw;

-- Com a últim pas, escullo canviar nom d'una taula, per evitar malentesos amb la bbdd creada a l'Ex.4
RENAME TABLE transactions TO transaction;

		-- === Foto finish ===
SELECT 'customers' AS taula, COUNT(*) AS registres FROM customers
UNION ALL SELECT 'credit_cards', COUNT(*) FROM credit_cards
UNION ALL SELECT 'companies', COUNT(*) FROM companies
UNION ALL SELECT 'transaction', COUNT(*) FROM transaction;
-- ============================================================
-- N1 · Ex.9: Subconsulta: usuaris amb més de 80 transaccions
-- ============================================================
USE buyers_club;

SELECT first_name, surname
FROM customers
WHERE customer_id IN (
	SELECT user_id
	FROM transaction
	GROUP BY user_id
   	HAVING COUNT(transaction_id) >80
);

		-- Check quants usuaris hi ha amb +80 transaccions
SELECT user_id,
	COUNT(transaction_id) AS total_transaccions
FROM transaction
GROUP BY user_id
ORDER BY total_transaccions DESC;
-- ============================================================
-- N1 · Ex.10: Mitjana de compra per targeta — Donec Ltd
-- ============================================================
USE buyers_club;

SELECT c.company_name,
	cc.iban,
	ROUND(AVG(t.amount),2) AS mitjana_compres
FROM transaction t
JOIN credit_cards cc ON t.card_id=cc.cc_id
JOIN companies c ON t.business_id=c.company_id
WHERE c.company_name = 'Donec Ltd'
GROUP BY c.company_name,cc.iban
ORDER BY mitjana_compres DESC;

			-- ======== Nivell 2 ========

-- ============================================================
-- N2 · Ex.1: Top 5 dies per ingressos
-- ============================================================
USE buyers_club;

SELECT DATE(t.transaction_date) AS dia, SUM(t.amount) AS Top5_vendes
FROM transaction t
GROUP BY DATE(t.transaction_date)
ORDER BY Top5_vendes DESC
LIMIT 5;
-- ============================================================
-- N2 · Ex.2: Transaccions de 350-400€ en 3 dates
-- ============================================================
USE buyers_club;

SELECT c.company_name, c.phone, c.country,
	DATE(t.transaction_date) AS transaction_date, t.amount
FROM transaction t
JOIN companies c ON t.business_id = c.company_id
WHERE t.amount
	BETWEEN 350 AND 400
AND DATE(t.transaction_date)
	IN ('2015-04-29', '2018-07-20', '2024-03-13')
ORDER BY t.amount DESC;
-- ============================================================
-- N2 · Ex.3: Empreses segons volum de transaccions (CASE WHEN)
-- ============================================================
USE buyers_club;

SELECT company_name,
	COUNT(*) AS total_transactions,
		CASE WHEN COUNT(*) >= 400 THEN 'Igual o més de 400'
			ELSE 'Menys de 400'
		END AS transaction_category
FROM transaction t
JOIN companies c ON t.business_id = c.company_id
GROUP BY company_name
ORDER BY total_transactions;
-- ============================================================
-- N2 · Ex.4: Eliminació d'un registre (DELETE)
-- ============================================================
USE buyers_club;

SELECT *					-- Miro registre
FROM transaction
WHERE transaction_id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

DELETE FROM transaction		-- Elimino registre
WHERE transaction_id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

SELECT *					-- Confirmo eliminació registre
FROM transaction
WHERE transaction_id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';
-- ============================================================
-- N2 · Ex.5: Vista VistaMarketing
-- ============================================================
USE buyers_club;

CREATE VIEW VistaMarketing AS								-- Creació VistaMarketing
	SELECT c.company_name, c.phone, c.country, 
		ROUND(AVG(t.amount) ,2) AS avg_purchase_company		-- Per escurçar 6 decimals
	FROM transaction t
	JOIN companies c ON t.business_id=c.company_id
	GROUP BY c.company_name, c.phone, c.country
	ORDER BY avg_purchase_company DESC
;

SELECT * FROM VistaMarketing;								-- Mostra VistaMarketing

			-- ======== Nivell 3 ========
-- ============================================================
-- N3 · Ex.1: Estat de les targetes (3 últimes transaccions)
-- ============================================================
USE buyers_club;

CREATE TABLE card_status AS								-- Crear taula nova amb status de cada targeta segons les seves 3 últimes transaccions
SELECT  card_id,
        CASE WHEN SUM(declined) = 3 THEN 'inactive'
             ELSE 'active'
        END AS card_state
FROM (
	SELECT card_id, declined, transaction_date,
	ROW_NUMBER() OVER (PARTITION BY card_id ORDER BY transaction_date DESC) AS recent_rank
	FROM transaction)
AS ranked
WHERE recent_rank <= 3
GROUP BY card_id;

SELECT COUNT(*) AS total_cards          				-- Validació: una fila per targeta
FROM card_status;

SELECT declined_total, COUNT(*) AS num_cards			-- Comprovació: quantitat de targetes segons nombre de declinacions a les seves 3 últimes transaccions
FROM (
    SELECT card_id, SUM(declined) AS declined_total
    FROM (
        SELECT card_id, declined,
               ROW_NUMBER() OVER (PARTITION BY card_id ORDER BY transaction_date DESC) AS recent_rank
        FROM transaction
    ) AS ranked
    WHERE recent_rank <= 3
    GROUP BY card_id
) AS per_card
GROUP BY declined_total
ORDER BY declined_total;
-- ============================================================
-- N3 · Ex.2: Productes i vegades venudes (FIND_IN_SET)
-- ============================================================
USE buyers_club;

CREATE TABLE products (
	product_id      INT PRIMARY KEY,
    product_name    VARCHAR(50),
	price           DECIMAL(10,2),			-- netejar simbol moneda en LOAD
    colour          VARCHAR(9),
    weight          DECIMAL(5,2),
    warehouse_id    VARCHAR(6),
    category        VARCHAR(20),
    brand           VARCHAR(30),
    cost            DECIMAL(10,2),          -- netejar simbol moneda en LOAD
    launch_date     DATE                    -- ISO net, es carrega directament
);

-- Càrrega csv
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/IT_Academy/N3-Ex.2__products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
IGNORE 1 LINES
(product_id, product_name, @price, colour, weight, warehouse_id,
 category, brand, @cost, launch_date)
SET price = REPLACE(@price, '$', ''),
    cost  = REPLACE(@cost, '$', '');		-- netejes moneda

-- Validació càrrega
SELECT COUNT(*) FROM products;

-- Recompte vendes per producte, ordenat de més a menys venuts
SELECT p.product_id, p.product_name, COUNT(t.transaction_id) AS times_sold
FROM products p
JOIN transaction t ON FIND_IN_SET(p.product_id, t.product_ids)
GROUP BY p.product_id, p.product_name
ORDER BY times_sold DESC;
						-- ======== --