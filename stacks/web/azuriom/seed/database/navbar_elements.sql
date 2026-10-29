SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

-- La table `navbar_elements` et sa clé étrangère `parent_id` appartiennent aux
-- migrations Azuriom. Ce fichier ne contient que les entrées de démonstration.
INSERT INTO `navbar_elements` (`id`, `name`, `icon`, `value`, `position`, `type`, `parent_id`, `new_tab`) VALUES
(1, 'Accueil', 'bi bi-house', '#', 1, 'home', NULL, 0),
(2, 'Boutique', 'bi bi-shop', 'shop.home', 2, 'plugin', NULL, 0),
(3, 'Discord', 'bi bi-discord', 'https://discord.altherneum.fr', 3, 'link', NULL, 1)
ON DUPLICATE KEY UPDATE
    `name` = VALUES(`name`),
    `icon` = VALUES(`icon`),
    `value` = VALUES(`value`),
    `position` = VALUES(`position`),
    `type` = VALUES(`type`),
    `parent_id` = VALUES(`parent_id`),
    `new_tab` = VALUES(`new_tab`);
