SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

-- La table `permissions` appartient aux migrations Azuriom. On ajoute seulement
-- les permissions de démonstration manquantes : les permissions existantes et
-- personnalisées ne sont ni supprimées ni écrasées.
INSERT INTO `permissions` (`permission`, `role_id`)
SELECT 'comments.create', 1
WHERE NOT EXISTS (
    SELECT 1 FROM `permissions`
    WHERE `permission` = 'comments.create' AND `role_id` = 1
);

INSERT INTO `permissions` (`permission`, `role_id`)
SELECT 'comments.create', 2
WHERE NOT EXISTS (
    SELECT 1 FROM `permissions`
    WHERE `permission` = 'comments.create' AND `role_id` = 2
);
