SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

-- La table `images` appartient aux migrations Azuriom. L'upsert sur `file`
-- (clé unique) met à jour les images de démonstration sans toucher aux autres.
INSERT INTO `images` (`name`, `file`, `type`, `created_at`, `updated_at`) VALUES
('background', 'background.jpg', 'image/jpeg', '2024-04-27 12:39:57', '2024-04-27 12:39:57'),
('gif', 'gif.gif', 'image/gif', '2024-04-27 12:43:24', '2024-04-27 12:43:24'),
('icone', 'icone.png', 'image/png', '2024-04-27 12:44:11', '2024-04-27 12:44:11'),
('logogif', 'small.gif', 'image/gif', '2024-04-27 12:44:11', '2024-04-27 12:44:11'),
('logopng', 'small.png', 'image/png', '2024-04-27 12:44:11', '2024-04-27 12:44:11')
ON DUPLICATE KEY UPDATE
    `name` = VALUES(`name`),
    `type` = VALUES(`type`),
    `created_at` = VALUES(`created_at`),
    `updated_at` = VALUES(`updated_at`);
