-- V026: Hero (class 10) client ChrClasses DisplayPower 0 -> 127, matching every other class in patch-n.
-- With 0 the 3.3.5 client treats Hero as mana-only and never regenerates spent runes (DK abilities drafted by
-- Heroes stay "not enough runes"). 127 is what all classless classes ship with (commit 02bcaf7, Dec 2025).
-- Client DBC only: the server override row (data/sql/db-world/hero_class.sql, chrclasses_dbc) stays 0 = mana.
-- V023 is left untouched so its Flyway checksum is unchanged.
update main.ChrClasses set display_power = 127 where id = 10;
