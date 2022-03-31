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

CREATE SEQUENCE objednavka_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE setkani_id START WITH 1 INCREMENT BY 1;



CREATE TABLE "FAMILIE"
(
    "nazev" VARCHAR(100) NOT NULL PRIMARY KEY,
    "typ podnikani" VARCHAR(100) NOT NULL
);

CREATE TABLE "MAFIAN"
(
    "rodne cislo" VARCHAR(100) NOT NULL PRIMARY KEY
        CHECK (mod("rodne cislo", 11) = 0 AND REGEXP_LIKE("rodne cislo", '^[0-9]{2}[0-1][0-9][0-3][0-9][0-9]{4}$')),
    "jmeno" VARCHAR(100),
    "mesto" VARCHAR(100),
    "ulice" VARCHAR(100),
    "PSC" INT,
    "narodnost" VARCHAR(100),
    "familie" VARCHAR(100),
    constraint "mafian_familie_fk" FOREIGN KEY ("familie") REFERENCES FAMILIE("nazev")
);

CREATE TABLE "DON"
(
    "rodne cislo" VARCHAR(100) NOT NULL PRIMARY KEY,
    constraint "don_mafian_fk" FOREIGN KEY("rodne cislo") REFERENCES MAFIAN("rodne cislo"),
    "velikost bot" INT NOT NULL,
    "barva oci" VARCHAR(100) NOT NULL,
    "postava" VARCHAR(100) NOT NULL
);


CREATE TABLE "RAJON"
(
    "nazev" VARCHAR(100) NOT NULL PRIMARY KEY,
    "souradnice" varchar(1000) NOT NULL,
    "rozloha" NUMBER NOT NULL,
    "PSC" INT NOT NULL,
    "familie" VARCHAR(100),
    constraint "rajon_familie_fk" FOREIGN KEY ("familie") REFERENCES FAMILIE("nazev")
);

CREATE TABLE "OBJEDNAVKA"
(
    "id" INT DEFAULT objednavka_id.nextval PRIMARY KEY,
    "cena" INT NOT NULL,
    "druh" VARCHAR(100) NOT NULL,
    "rc mafiana" VARCHAR(100),
    constraint "objednavka_mafian_fk" FOREIGN KEY ("rc mafiana") REFERENCES MAFIAN("rodne cislo")
);

CREATE TABLE "SETKANI"
(
    "id" INT DEFAULT setkani_id.nextval PRIMARY KEY,
    "cil" varchar(100) NOT NULL,
    "cas" TIMESTAMP NOT NULL,
    "rajon" VARCHAR(100),
    constraint "setkani_rajon_fk" FOREIGN KEY ("rajon") REFERENCES RAJON("nazev")
);

CREATE TABLE "SETKANI UCAST"
(
    "id setkani" INT NOT NULL,
    "rc dona" VARCHAR(100) NOT NULL,

    constraint "setkani_ucast_fk" FOREIGN KEY ("id setkani") REFERENCES SETKANI("id"),
    constraint "setkani_ucast_don_fk" FOREIGN KEY ("rc dona") REFERENCES MAFIAN("rodne cislo")
);

CREATE TABLE "CINNOST"
(
    "nazev" VARCHAR(100) NOT NULL PRIMARY KEY,
    "trvani" VARCHAR(100) NOT NULL,
    "nebezpeci" VARCHAR(100),
    "rajon" VARCHAR(100) NOT NULL,
    constraint "cinnost_rajon_fk" FOREIGN KEY ("rajon") REFERENCES RAJON("nazev"),
    "familie" VARCHAR(100) NOT NULL,
    constraint "cinnost_familie_fk" FOREIGN KEY("familie") REFERENCES FAMILIE("nazev")
);

CREATE TABLE "CINNOST UCAST"
(
    "nazev cinnosti" VARCHAR(100) NOT NULL,
    "rc mafiana" VARCHAR(100) NOT NULL,

    constraint "cinnost_ucast_fk" FOREIGN KEY ("nazev cinnosti") REFERENCES CINNOST("nazev"),
    constraint "cinnost_ucast_mafian_fk" FOREIGN KEY ("rc mafiana") REFERENCES MAFIAN("rodne cislo")
);

CREATE TABLE "VRAZDA"
(
    "nazev" VARCHAR(100) NOT NULL PRIMARY KEY,
    constraint "vrazda_cinnost_fk" FOREIGN KEY ("nazev") REFERENCES CINNOST("nazev"),
    "zakaznik" VARCHAR(100),
    "obet" VARCHAR(100) NOT NULL,
    "zpusob zabiti" VARCHAR(100) NOT NULL,
    "rc dona" VARCHAR(100),
    constraint "vrazda_don_fk" FOREIGN KEY ("rc dona") REFERENCES DON("rodne cislo")
);

INSERT INTO "FAMILIE"
    ("nazev", "typ podnikani") VALUES ('Giuseppovi', 'tisk peněz');
INSERT INTO "FAMILIE"
    ("nazev", "typ podnikani") VALUES ('Paniniovi', 'vraždy');

INSERT INTO "MAFIAN"
    ("rodne cislo", "jmeno", "mesto", "ulice", PSC, "narodnost", "familie") VALUES
    ('7911288099', 'Peperoni Giuseppe', 'Brno', 'Palachova', 12345, 'CZ', 'Giuseppovi');
INSERT INTO "MAFIAN"
    ("rodne cislo", "jmeno", "mesto", "ulice", PSC, "narodnost", "familie") VALUES
    ('8504020041', 'Salami Giuseppe', 'Brno', 'Kolejní', 12121, 'SK', 'Giuseppovi');
INSERT INTO "MAFIAN"
    ("rodne cislo", "jmeno", "mesto", "ulice", PSC, "narodnost", "familie") VALUES
    ('6902154380', 'Hawai Panini', 'Blansko', 'Nějaká', 19874, 'CZ', 'Paniniovi');

INSERT INTO "DON"
    ("rodne cislo", "velikost bot", "barva oci", "postava") VALUES
    ('7911288099', 40, 'modrá', 'hubená');
INSERT INTO "DON"
    ("rodne cislo", "velikost bot", "barva oci", "postava") VALUES
    ('6902154380', 44, 'hnědá', 'obézní');

INSERT INTO "RAJON"
    ("nazev", "souradnice", "rozloha", PSC, "familie") VALUES
    ('Náměstí svobody', '121554 4545458', '1000', 54878, 'Paniniovi');
INSERT INTO "RAJON"
    ("nazev", "souradnice", "rozloha", PSC) VALUES
    ('Lužánky', '445445 454545', '777', 97979);

INSERT INTO "CINNOST"
    ("nazev", "trvani", "nebezpeci", "rajon", "familie") VALUES
    ('Krádež šperků', '1h 20min', 'vysoké', 'Lužánky', 'Paniniovi');
INSERT INTO "CINNOST"
    ("nazev", "trvani", "nebezpeci", "rajon", "familie") VALUES
    ('Vražda hlasitého souseda', '20min', 'nizké', 'Náměstí svobody', 'Giuseppovi');

INSERT INTO "VRAZDA"
    ("nazev", "zakaznik", "obet", "zpusob zabiti", "rc dona") VALUES
    ('Vražda hlasitého souseda', 'Josef Novák', 'Bohuslav Modrý', 'zastřelení', '7911288099');

INSERT INTO "CINNOST UCAST"
    ("nazev cinnosti", "rc mafiana") VALUES ('Vražda hlasitého souseda', '8504020041');

INSERT INTO "OBJEDNAVKA"
    ("cena", "druh", "rc mafiana") VALUES ('200000', 'zelenina', '6902154380');
INSERT INTO "OBJEDNAVKA"
    ("cena", "druh", "rc mafiana") VALUES ('124444', 'kokain', '8504020041');

INSERT INTO "SETKANI"
    ("cil", "cas", "rajon") VALUES ('Plány na příští měsíc', '4-4-2022 12:00:00', 'Lužánky');

INSERT INTO "SETKANI UCAST"
    ("id setkani", "rc dona") VALUES ('1', '7911288099');
INSERT INTO "SETKANI UCAST"
    ("id setkani", "rc dona") VALUES ('1', '6902154380');*/