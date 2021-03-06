-- Project: IDS
-- Authors:
    -- Roman Vintoňak
    -- Marko Kubrachenko
-- Date: 03.04.2022

DROP INDEX "rajon_index";

DROP TABLE "FAMILIE" CASCADE CONSTRAINTS;
DROP TABLE "MAFIAN" CASCADE CONSTRAINTS;
DROP TABLE "RAJON" CASCADE CONSTRAINTS;
DROP TABLE "OBJEDNAVKA" CASCADE CONSTRAINTS;
DROP TABLE "SETKANI" CASCADE CONSTRAINTS;
DROP TABLE "SETKANI UCAST" CASCADE CONSTRAINTS;
DROP TABLE "CINNOST" CASCADE CONSTRAINTS;
DROP TABLE "CINNOST UCAST" CASCADE CONSTRAINTS;
DROP TABLE "DON" CASCADE CONSTRAINTS;
DROP TABLE "VRAZDA" CASCADE CONSTRAINTS;

DROP SEQUENCE objednavka_id;
DROP SEQUENCE setkani_id;

DROP MATERIALIZED VIEW "objednavky";

CREATE SEQUENCE objednavka_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE setkani_id START WITH 1 INCREMENT BY 1;

------------ CREATE TABLES ------------

CREATE TABLE "FAMILIE"
(
    "nazev" VARCHAR(100) NOT NULL PRIMARY KEY,
    "typ podnikani" VARCHAR(100) NOT NULL
);

CREATE TABLE "MAFIAN"
(
    "rodne cislo" VARCHAR(100) NOT NULL PRIMARY KEY,
        CHECK (mod("rodne cislo", 11) = 0 AND REGEXP_LIKE("rodne cislo", '^\d{2}[0-1]\d[0-3]\d\d{4}$')),
    "jmeno" VARCHAR(100),
    "mesto" VARCHAR(100),
    "ulice" VARCHAR(100),
    "PSC" INT,
    "narodnost" VARCHAR(100),
    "familie" VARCHAR(100),
    CONSTRAINT "mafian_familie_fk" FOREIGN KEY ("familie") REFERENCES FAMILIE("nazev")
);

CREATE TABLE "DON"
(
    "rodne cislo" VARCHAR(100) NOT NULL PRIMARY KEY,
    CONSTRAINT "don_mafian_fk" FOREIGN KEY("rodne cislo") REFERENCES MAFIAN("rodne cislo"),
    "velikost bot" INT NOT NULL,
    "barva oci" VARCHAR(100) NOT NULL,
    "postava" VARCHAR(100) NOT NULL
);


CREATE TABLE "RAJON"
(
    "nazev" VARCHAR(100) NOT NULL PRIMARY KEY,
    "souradnice" VARCHAR(1000) NOT NULL,
    "rozloha" NUMBER NOT NULL,
    "PSC" INT NOT NULL,
    "familie" VARCHAR(100),
    CONSTRAINT "rajon_familie_fk" FOREIGN KEY ("familie") REFERENCES FAMILIE("nazev")
);

CREATE TABLE "OBJEDNAVKA"
(
    "id" INT DEFAULT objednavka_id.nextval PRIMARY KEY,
    "cena" INT NOT NULL,
    "druh" VARCHAR(100) NOT NULL,
    "rc mafiana" VARCHAR(100),
    CONSTRAINT "objednavka_mafian_fk" FOREIGN KEY ("rc mafiana") REFERENCES MAFIAN("rodne cislo")
);

CREATE TABLE "SETKANI"
(
    "id" INT DEFAULT setkani_id.nextval PRIMARY KEY,
    "cil" VARCHAR(100) NOT NULL,
    "cas" TIMESTAMP NOT NULL,
    "rajon" VARCHAR(100),
    CONSTRAINT "setkani_rajon_fk" FOREIGN KEY ("rajon") REFERENCES RAJON("nazev")
);

CREATE TABLE "SETKANI UCAST"
(
    "id setkani" INT NOT NULL,
    "rc dona" VARCHAR(100) NOT NULL,

    CONSTRAINT "setkani_ucast_fk" FOREIGN KEY ("id setkani") REFERENCES SETKANI("id"),
    CONSTRAINT "setkani_ucast_don_fk" FOREIGN KEY ("rc dona") REFERENCES MAFIAN("rodne cislo"),
    PRIMARY KEY("id setkani", "rc dona")
);

CREATE TABLE "CINNOST"
(
    "nazev" VARCHAR(100) NOT NULL PRIMARY KEY,
    "trvani" VARCHAR(100) NOT NULL,
    "nebezpeci" VARCHAR(100),
    "rajon" VARCHAR(100) NOT NULL,
    CONSTRAINT "cinnost_rajon_fk" FOREIGN KEY ("rajon") REFERENCES RAJON("nazev"),
    "familie" VARCHAR(100) NOT NULL,
    CONSTRAINT "cinnost_familie_fk" FOREIGN KEY("familie") REFERENCES FAMILIE("nazev")
);

CREATE TABLE "CINNOST UCAST"
(
    "nazev cinnosti" VARCHAR(100) NOT NULL,
    "rc mafiana" VARCHAR(100) NOT NULL,

    CONSTRAINT "cinnost_ucast_fk" FOREIGN KEY ("nazev cinnosti") REFERENCES CINNOST("nazev"),
    CONSTRAINT "cinnost_ucast_mafian_fk" FOREIGN KEY ("rc mafiana") REFERENCES MAFIAN("rodne cislo"),
    PRIMARY KEY("nazev cinnosti", "rc mafiana")
);

CREATE TABLE "VRAZDA"
(
    "nazev" VARCHAR(100) NOT NULL PRIMARY KEY,
    CONSTRAINT "vrazda_cinnost_fk" FOREIGN KEY ("nazev") REFERENCES CINNOST("nazev"),
    "zakaznik" VARCHAR(100),
    "obet" VARCHAR(100) NOT NULL,
    "zpusob zabiti" VARCHAR(100) NOT NULL,
    "rc dona" VARCHAR(100),
    CONSTRAINT "vrazda_don_fk" FOREIGN KEY ("rc dona") REFERENCES DON("rodne cislo")
);

------------ TRIGGERS ------------

-- Don se nesmi nezucastni zadne kriminalni cinnosti.
-- Trigger provadi kontrolu pred ulozenim do tabulky "CINNOST UCAST".
CREATE OR REPLACE TRIGGER kontrola_cinnost_ucast
    BEFORE INSERT OR UPDATE OF "rc mafiana" ON "CINNOST UCAST"
    FOR EACH ROW
    DECLARE
        je_don NUMBER;
    BEGIN
        SELECT COUNT(*) INTO je_don FROM DON WHERE DON."rodne cislo" = :NEW."rc mafiana";
        IF je_don > 0 THEN
            raise_application_error(-20202,'Don si nikdy nespini ruce!');
        END IF;
    END;
/

-- Don nemuze na vice setkani ve stejny den.
-- Trigger provadi kontrolu, zda Don nebyl zapsan do setkani, pokud v tento den uz neco ma.
CREATE OR REPLACE TRIGGER kontrola_setkani_ucast
    BEFORE INSERT OR UPDATE OF "rc dona" ON "SETKANI UCAST"
    FOR EACH ROW
    DECLARE
        ma_setkani NUMBER;
    BEGIN
        SELECT COUNT(*) INTO ma_setkani FROM "SETKANI UCAST" JOIN "SETKANI"
            ON "SETKANI UCAST"."id setkani" = SETKANI."id" WHERE "rc dona" = :NEW."rc dona" AND
                TRUNC("cas") = (SELECT TRUNC("cas") FROM SETKANI WHERE "id" = :NEW."id setkani");
        IF ma_setkani > 0 THEN
            raise_application_error(-20201,'Don v tento den uz ma setkani!');
        END IF;
    END;
/







------------ TEST DATA ------------

INSERT INTO "FAMILIE"
    ("nazev", "typ podnikani") VALUES ('Giuseppovi', 'tisk peněz');
INSERT INTO "FAMILIE"
    ("nazev", "typ podnikani") VALUES ('Paniniovi', 'vraždy');
INSERT INTO "FAMILIE"
    ("nazev", "typ podnikani") VALUES ('Carbonarovi', 'dealování drog');

INSERT INTO "MAFIAN"
    ("rodne cislo", "jmeno", "mesto", "ulice", "PSC", "narodnost", "familie") VALUES
    ('7911288099', 'Peperoni Giuseppe', 'Brno', 'Palachova', 12345, 'CZ', 'Giuseppovi');
INSERT INTO "MAFIAN"
    ("rodne cislo", "jmeno", "mesto", "ulice", "PSC", "narodnost", "familie") VALUES
    ('8504020041', 'Salami Giuseppe', 'Brno', 'Kolejní', 12121, 'SK', 'Giuseppovi');
INSERT INTO "MAFIAN"
    ("rodne cislo", "jmeno", "mesto", "ulice", "PSC", "narodnost", "familie") VALUES
    ('6902154380', 'Hawai Panini', 'Blansko', 'Nějaká', 19874, 'CZ', 'Paniniovi');
INSERT INTO "MAFIAN"
    ("rodne cislo", "jmeno", "mesto", "ulice", "PSC", "narodnost", "familie") VALUES
    ('8810104919', 'Pensare Carbonar', 'Olomouc', 'Kounicova', 56274, 'PL', 'Carbonarovi');
INSERT INTO "MAFIAN"
    ("rodne cislo", "jmeno", "mesto", "ulice", "PSC", "narodnost", "familie") VALUES
    ('8405148125', 'Scusi Carbonar', 'Olomouc', 'Francouzská', 44163, 'PL', 'Carbonarovi');
INSERT INTO "MAFIAN"
    ("rodne cislo", "jmeno", "mesto", "ulice", "PSC", "narodnost", "familie") VALUES
    ('0204191493', 'Andare Carbonar', 'Olomouc', 'Pražská', 44163, 'PL', 'Carbonarovi');

INSERT INTO "DON"
    ("rodne cislo", "velikost bot", "barva oci", "postava") VALUES
    ('7911288099', 40, 'modrá', 'hubená');
INSERT INTO "DON"
    ("rodne cislo", "velikost bot", "barva oci", "postava") VALUES
    ('8810104919', 43, 'zelená', 'hubená');
INSERT INTO "DON"
    ("rodne cislo", "velikost bot", "barva oci", "postava") VALUES
    ('6902154380', 44, 'hnědá', 'obézní');

INSERT INTO "RAJON"
    ("nazev", "souradnice", "rozloha", "PSC", "familie") VALUES
    ('Náměstí svobody', '121554 4545458', '1000', 54878, 'Paniniovi');
INSERT INTO "RAJON"
    ("nazev", "souradnice", "rozloha", "PSC") VALUES
    ('Lužánky', '445445 454545', '777', 97979);
INSERT INTO "RAJON"
    ("nazev", "souradnice", "rozloha", "PSC", "familie") VALUES
    ('Ponava', '673455 417342', '8080', 70200, 'Carbonarovi');

INSERT INTO "CINNOST"
    ("nazev", "trvani", "nebezpeci", "rajon", "familie") VALUES
    ('Krádež šperků', '1h 20min', 'vysoké', 'Lužánky', 'Paniniovi');
INSERT INTO "CINNOST"
    ("nazev", "trvani", "nebezpeci", "rajon", "familie") VALUES
    ('Vražda hlasitého souseda', '20min', 'nizké', 'Náměstí svobody', 'Giuseppovi');
INSERT INTO "CINNOST"
    ("nazev", "trvani", "nebezpeci", "rajon", "familie") VALUES
    ('Dealování drog', '4h 30min', 'střední', 'Ponava', 'Carbonarovi');

INSERT INTO "VRAZDA"
    ("nazev", "zakaznik", "obet", "zpusob zabiti", "rc dona") VALUES
    ('Vražda hlasitého souseda', 'Josef Novák', 'Bohuslav Modrý', 'zastřelení', '7911288099');

INSERT INTO "CINNOST UCAST"
    ("nazev cinnosti", "rc mafiana") VALUES ('Vražda hlasitého souseda', '8504020041');
INSERT INTO "CINNOST UCAST"
    ("nazev cinnosti", "rc mafiana") VALUES ('Dealování drog', '8405148125');
INSERT INTO "CINNOST UCAST"
    ("nazev cinnosti", "rc mafiana") VALUES ('Dealování drog', '0204191493');

INSERT INTO "OBJEDNAVKA"
    ("cena", "druh", "rc mafiana") VALUES ('200000', 'zelenina', '6902154380');
INSERT INTO "OBJEDNAVKA"
    ("cena", "druh", "rc mafiana") VALUES ('124444', 'kokain', '8504020041');
INSERT INTO "OBJEDNAVKA"
    ("cena", "druh", "rc mafiana") VALUES ('14999', 'pistol', '8810104919');
INSERT INTO "OBJEDNAVKA"
    ("cena", "druh", "rc mafiana") VALUES ('5000', 'kapesní nůž', '8810104919');

INSERT INTO "SETKANI"
    ("cil", "cas", "rajon") VALUES ('Plány na příští měsíc', TO_DATE('2022-04-04 12:00', 'YYYY-MM-DD HH24:MI'), 'Lužánky');
INSERT INTO "SETKANI"
    ("cil", "cas", "rajon") VALUES ('Aliance mezi Paniniovimi a Carbonarovimi', TO_DATE('2022-05-01 18:00', 'YYYY-MM-DD HH24:MI'), 'Ponava');

INSERT INTO "SETKANI UCAST"
    ("id setkani", "rc dona") VALUES ('1', '7911288099');
INSERT INTO "SETKANI UCAST"
    ("id setkani", "rc dona") VALUES ('1', '6902154380');
INSERT INTO "SETKANI UCAST"
    ("id setkani", "rc dona") VALUES ('1', '8810104919');
INSERT INTO "SETKANI UCAST"
    ("id setkani", "rc dona") VALUES ('2', '6902154380');
INSERT INTO "SETKANI UCAST"
    ("id setkani", "rc dona") VALUES ('2', '8810104919');



------------ SELECTS ------------

-- Co si objednali mafiani a kolik jim to stalo? (2 joined tables)
SELECT "jmeno", "druh", "cena" FROM "OBJEDNAVKA" JOIN "MAFIAN" ON "OBJEDNAVKA"."rc mafiana" = "MAFIAN"."rodne cislo" ORDER BY "cena";

-- Kteri Doni maji velikost bot 43 nebo 44? (2 joined tables)
SELECT "jmeno" FROM "MAFIAN" JOIN "DON" ON "MAFIAN"."rodne cislo" = "DON"."rodne cislo"
    WHERE "velikost bot" = '43' OR "velikost bot" = '44';

-- Kteri mafiani se zucastni cinnosti, ktere budou probihat v rajonu "Ponava"? (3 joined tables)
SELECT "jmeno" FROM "MAFIAN" JOIN "CINNOST UCAST" ON MAFIAN."rodne cislo" = "CINNOST UCAST"."rc mafiana"
    JOIN "CINNOST" ON "CINNOST UCAST"."nazev cinnosti" = "CINNOST"."nazev"
        WHERE "rajon" = 'Ponava';

-- Kolik mafianu obsahujij jednotlive familie? (COUNT and GROUP BY)
SELECT "familie", COUNT(*) FROM "MAFIAN" GROUP BY "familie";

-- Kolik mafianu bere ucast v jednotlivych cinnostech? (COUNT and GROUP BY)
SELECT "nazev", COUNT(*) "pocet mafianu" FROM "CINNOST" JOIN "CINNOST UCAST" ON "CINNOST"."nazev" = "CINNOST UCAST"."nazev cinnosti" GROUP BY "nazev";

-- Jakou postavu a velikost bot maji Doni, kteri uz alespon jednou objednavali vrazdu? (EXISTS)
SELECT "postava", "velikost bot" FROM "DON" WHERE "rodne cislo" = (
    SELECT "rodne cislo" FROM "MAFIAN" WHERE "rodne cislo" = "DON"."rodne cislo" AND EXISTS (
        SELECT * FROM "VRAZDA" WHERE "rc dona" = "MAFIAN"."rodne cislo"));

-- Kteri Doni se zucastni setkani, ktere je naplanovano 2022-05-01 18:00? (IN)
SELECT "jmeno" FROM "MAFIAN" WHERE "rodne cislo" IN (
    SELECT "rc dona" FROM "DON" JOIN "SETKANI UCAST" ON "DON"."rodne cislo" = "SETKANI UCAST"."rc dona"
        JOIN "SETKANI" ON "SETKANI UCAST"."id setkani" = "SETKANI"."id"
            WHERE "cas" = TO_DATE('2022-05-01 18:00', 'YYYY-MM-DD HH24:MI'));

---------- EXPLAIN PLAN ----------

-- Kolikrat se mafiani zucastnili cinnosti podle jejich nebezpeci?
EXPLAIN PLAN FOR
    SELECT "nebezpeci", COUNT("rc mafiana") AS celkove FROM "CINNOST" JOIN "CINNOST UCAST"
    ON CINNOST."nazev" = "CINNOST UCAST"."nazev cinnosti" WHERE "rajon" = 'Ponava' GROUP BY "nebezpeci";
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Index pro seskupeni podle nazvu rajonu.
CREATE INDEX "rajon_index" ON "CINNOST" ("rajon");

-- Ten stejny dotaz, ale za pouziti indexu "rajon_index".
EXPLAIN PLAN FOR
    SELECT "nebezpeci", COUNT("rc mafiana") AS celkove FROM "CINNOST" JOIN "CINNOST UCAST"
    ON CINNOST."nazev" = "CINNOST UCAST"."nazev cinnosti" WHERE "rajon" = 'Ponava' GROUP BY "nebezpeci";
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

---------- MATERIALIZED VIEW  ----------

CREATE MATERIALIZED VIEW "objednavky" AS
    SELECT * FROM OBJEDNAVKA;

-- Zmena hodnot v tabulce OBJEDNAVKA
UPDATE "OBJEDNAVKA" SET "cena" = 3500000 WHERE "id" = 2;

-- V materializovanem pohledu se cena objednavky nezmenila,
SELECT * FROM "objednavky";
-- ale v tabulce -- ano.
SELECT * FROM OBJEDNAVKA;

------------ STORED PROCEDURES ------------

-- Procedura vratí počet mafiánů v zadané familie do proměnné "pocet"
CREATE OR REPLACE PROCEDURE pocet_mafianu("nazev familie" IN VARCHAR, "pocet" OUT INT) AS
    "nazev" "FAMILIE"."nazev"%TYPE;
    "hledany nazev" "FAMILIE"."nazev"%TYPE;
    CURSOR "cursor" IS SELECT "nazev" FROM "FAMILIE";
BEGIN
    SELECT "nazev" INTO "hledany nazev" FROM FAMILIE WHERE "nazev" = "nazev familie";
    "pocet" := 0;
    OPEN "cursor";
    LOOP
        FETCH "cursor" INTO "nazev";
        EXIT WHEN "cursor"%NOTFOUND;
        IF "nazev" = "hledany nazev" THEN
            "pocet" := "pocet" + 1;
        end if;
    end loop;
    CLOSE "cursor";
    EXCEPTION WHEN NO_DATA_FOUND THEN
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Zadaná familie neexistuje!');
    end;
END;

-- Příklad provedení procedury pocet_mafianu
DECLARE
    pocet INT;
BEGIN
    pocet_mafianu('Paniniovi', pocet);
END;

-- Procedura vypíše názvy všech familií, počet vlastněných rajónů a jména jejich donů
CREATE OR REPLACE PROCEDURE print_fam_info AS
    "nazev familie" "FAMILIE"."nazev"%TYPE;
    "jmeno dona" "MAFIAN"."jmeno"%TYPE;
    "pocet rajonu" NUMBER;
    CURSOR "cursor" IS SELECT "nazev" FROM "FAMILIE";
BEGIN
    OPEN "cursor";
    LOOP
        FETCH "cursor" INTO "nazev familie";
        EXIT WHEN "cursor"%NOTFOUND;
        SELECT "jmeno" INTO "jmeno dona"
            FROM MAFIAN, DON, FAMILIE
            WHERE "nazev familie" = "FAMILIE"."nazev"
              AND "FAMILIE"."nazev" = "MAFIAN"."familie"
              AND "MAFIAN"."rodne cislo" = "DON"."rodne cislo"
              FETCH FIRST 1 ROWS ONLY;
        SELECT COUNT(*) INTO "pocet rajonu" FROM RAJON WHERE "RAJON"."familie" = "nazev familie";
        DBMS_OUTPUT.PUT_LINE('Familie ' || "nazev familie" || ' vlastní ' || "pocet rajonu" || ' rajónů a její don je ' || "jmeno dona");
    end loop;
end;

-- Provedení procedury print_fam_info
BEGIN
    print_fam_info;
end;


------------ PRIVILEGES ------------

-- Vsechna prava ke vsem tabulkam.
GRANT ALL ON "FAMILIE" TO XVINTO00;
GRANT ALL ON "MAFIAN" TO XVINTO00;
GRANT ALL ON "DON" TO XVINTO00;
GRANT ALL ON "RAJON" TO XVINTO00;
GRANT ALL ON "OBJEDNAVKA" TO XVINTO00;
GRANT ALL ON "SETKANI" TO XVINTO00;
GRANT ALL ON "SETKANI UCAST" TO XVINTO00;
GRANT ALL ON "CINNOST" TO XVINTO00;
GRANT ALL ON "CINNOST UCAST" TO XVINTO00;
GRANT ALL ON "VRAZDA" TO XVINTO00;

-- Prava k materializovanemu pohledu.
GRANT ALL ON "objednavky" TO XVINTO00;