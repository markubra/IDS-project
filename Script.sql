DROP TABLE "MAFIAN" CASCADE CONSTRAINTS;
DROP TABLE "FAMILIE" CASCADE CONSTRAINTS;
DROP TABLE "RAJON" CASCADE CONSTRAINTS;
DROP TABLE "OBJEDNAVKA" CASCADE CONSTRAINTS;
DROP TABLE "SETKANI" CASCADE CONSTRAINTS;
DROP TABLE "SETKANI UCAST" CASCADE CONSTRAINTS;
DROP TABLE "CINNOST" CASCADE CONSTRAINTS;
DROP TABLE "CINNOST UCAST" CASCADE CONSTRAINTS;



DROP SEQUENCE familie_id;
DROP SEQUENCE rajon_id;
DROP SEQUENCE objednavka_id;
DROP SEQUENCE setkani_id;
DROP SEQUENCE cinnost_id;

CREATE SEQUENCE familie_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE rajon_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE objednavka_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE setkani_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE cinnost_id START WITH 1 INCREMENT BY 1;

CREATE TABLE "MAFIAN"
(
    "rodne cislo" INT NOT NULL PRIMARY KEY,
    CHECK (mod("rodne cislo", 11) = 0 AND "rodne cislo" between 100000000 and 9999999999),
    "jmeno" VARCHAR(100),
    "bydliste" VARCHAR(1000),
    "narodnost" VARCHAR(100),
    "familie" INT
);

CREATE TABLE "FAMILIE"
(
    "id" INT DEFAULT familie_id.nextval PRIMARY KEY,
    "typ podnikani" VARCHAR(100),
    "don" INT,
    constraint "don_fk2" FOREIGN KEY ("don") REFERENCES MAFIAN("rodne cislo")
);

ALTER TABLE MAFIAN ADD FOREIGN KEY ("familie") REFERENCES FAMILIE("id");

CREATE TABLE "RAJON"
(
    "id" INT DEFAULT rajon_id.nextval PRIMARY KEY,
    "souradnice" varchar(1000) NOT NULL,
    "adresa" VARCHAR(1000) NOT NULL,
    "rozloha" NUMBER NOT NULL,
    "PSC" INT NOT NULL,
    "familie" INT,
    constraint "rajon_fk" FOREIGN KEY ("familie") REFERENCES FAMILIE("id")
);

CREATE TABLE "OBJEDNAVKA"
(
    "id" INT DEFAULT objednavka_id.nextval PRIMARY KEY,
    "cena" INT NOT NULL,
    "druh" VARCHAR(100) NOT NULL,
    "rodne_cislo" INT,
    constraint "objednavatel_fk" FOREIGN KEY ("rodne_cislo") REFERENCES MAFIAN("rodne cislo")
);

CREATE TABLE "SETKANI"
(
    "id" INT DEFAULT setkani_id.nextval PRIMARY KEY,
    "cil" varchar(100) NOT NULL,
    "cas" TIMESTAMP NOT NULL,
    "rajon" INT,
    constraint "rajon_fk2" FOREIGN KEY ("rajon") REFERENCES RAJON("id")
);

CREATE TABLE "SETKANI UCAST"
(
    "id setkani" INT NOT NULL PRIMARY KEY,
    "rc dona" INT NOT NULL,

    constraint "setkani_fk" FOREIGN KEY ("id setkani") REFERENCES SETKANI("id"),
    constraint "don_fk" FOREIGN KEY ("rc dona") REFERENCES MAFIAN("rodne cislo")
);

CREATE TABLE "CINNOST"
(
    "id" INT DEFAULT cinnost_id.nextval PRIMARY KEY,
    "nazev" VARCHAR(100) NOT NULL,
    "trvani" TIMESTAMP NOT NULL,
    "nebezpeci" VARCHAR(100)
);

CREATE TABLE "CINNOST UCAST"
(
    "id cinnosti" INT NOT NULL PRIMARY KEY,
    "rc mafiana" INT NOT NULL,

    constraint "cinnost_fk" FOREIGN KEY ("id cinnosti") REFERENCES SETKANI("id"),
    constraint "mafian_fk" FOREIGN KEY ("rc mafiana") REFERENCES MAFIAN("rodne cislo")
);


INSERT INTO "MAFIAN"
("jmeno", "rodne cislo", "bydliste", "narodnost") VALUES ('Nekdo', 220000000, 'Nádraží ', 'Narnie');

INSERT INTO "OBJEDNAVKA"
("cena", "druh", "rodne_cislo") VALUES (100, 'neco', 220000000);

INSERT INTO "FAMILIE"
("typ podnikani", "don") VALUES ('neco', 220000000);

INSERT INTO "RAJON"
("souradnice", "adresa", "rozloha", PSC, "familie") VALUES ('100 500', 'Abcde 123', 125, 500, 1);

