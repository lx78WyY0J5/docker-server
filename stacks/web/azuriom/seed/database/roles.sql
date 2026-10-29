SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

-- La table `roles` appartient aux migrations Azuriom. Les identifiants 1 et 2
-- sont ceux créés par le seeder d'Azuriom (Membre et Admin) et sont référencés
-- par `users.role_id` et `permissions.role_id` : on les met à jour en place.
INSERT INTO `roles` (`id`, `name`, `icon`, `color`, `power`, `is_admin`, `created_at`, `updated_at`) VALUES
(1, 'Membre', NULL, 'a5a5a5', 0, 0, '2024-08-20 18:44:30', '2024-08-20 18:44:30'),
(2, 'Admin', NULL, 'e10d11', 10, 1, '2024-08-20 18:44:30', '2024-08-20 18:44:30')
ON DUPLICATE KEY UPDATE
    `name` = VALUES(`name`),
    `icon` = VALUES(`icon`),
    `color` = VALUES(`color`),
    `power` = VALUES(`power`),
    `is_admin` = VALUES(`is_admin`),
    `created_at` = VALUES(`created_at`),
    `updated_at` = VALUES(`updated_at`);
