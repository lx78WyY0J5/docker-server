SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

INSERT INTO `shop_categories` (`id`, `name`, `slug`, `description`, `position`, `parent_id`, `cumulate_purchases`, `is_enabled`, `created_at`, `updated_at`) VALUES
(1, 'SkyBlock', 'skyblock', NULL, 0, NULL, 1, 1, '2024-04-28 13:44:40', '2024-04-28 13:44:40'),
(2, 'Survie', 'survie', NULL, 0, NULL, 1, 1, '2024-04-28 13:44:52', '2024-04-28 13:44:52'),
(3, 'Anarchie', 'anarchie', NULL, 0, NULL, 1, 1, '2024-04-28 13:45:03', '2024-04-28 13:45:03'),
(4, 'OP-Prison', 'op-prison', NULL, 0, NULL, 1, 1, '2024-04-28 13:45:16', '2024-04-28 13:45:16'),
(5, 'Hub', 'hub', NULL, 0, NULL, 1, 1, '2024-04-28 13:45:25', '2024-04-28 13:45:25'),
(6, 'Global', 'global', NULL, 0, NULL, 1, 1, '2024-04-28 13:45:36', '2024-04-28 13:45:43'),
(7, 'RPG', 'rpg', NULL, 0, NULL, 1, 1, '2024-04-28 13:46:01', '2024-04-28 13:46:01')
ON DUPLICATE KEY UPDATE
    `name` = VALUES(`name`),
    `slug` = VALUES(`slug`),
    `description` = VALUES(`description`),
    `position` = VALUES(`position`),
    `parent_id` = VALUES(`parent_id`),
    `cumulate_purchases` = VALUES(`cumulate_purchases`),
    `is_enabled` = VALUES(`is_enabled`),
    `created_at` = VALUES(`created_at`),
    `updated_at` = VALUES(`updated_at`);
