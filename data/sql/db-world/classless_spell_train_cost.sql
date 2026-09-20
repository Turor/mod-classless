-- Classless spell rank train costs.
-- Gold is copper, same unit as trainer_spell.MoneyCost.
-- Alternate currency is an item (custom token, emblem, etc.): set
-- currency_item_id + currency_count. Both gold and item are charged when
-- both are set. Token-only = money_cost 0. Gold-only = currency columns 0.
-- Honor/arena would be extra uint32 columns later; items cover custom tokens.
-- Seed from class trainers (trainer.Type = 0). INSERT IGNORE keeps later
-- overrides. Spells not in this table (starting ranks) cost nothing.

CREATE TABLE IF NOT EXISTS `classless_spell_train_cost`
(
    `spell_id`          INT UNSIGNED NOT NULL,
    `money_cost`        INT UNSIGNED NOT NULL DEFAULT 0,
    `currency_item_id`  INT UNSIGNED NOT NULL DEFAULT 0,
    `currency_count`    INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`spell_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `classless_spell_train_cost` (`spell_id`, `money_cost`, `currency_item_id`, `currency_count`)
SELECT ts.SpellId, MAX(ts.MoneyCost), 0, 0
FROM `trainer_spell` ts
INNER JOIN `trainer` t ON t.Id = ts.TrainerId
WHERE t.Type = 0
GROUP BY ts.SpellId;
