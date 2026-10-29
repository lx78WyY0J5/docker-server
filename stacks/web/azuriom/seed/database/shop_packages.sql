SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

INSERT INTO `shop_packages` (`id`, `category_id`, `name`, `short_description`, `description`, `position`, `image`, `price`, `commands`, `role_id`, `money`, `giftcard_balance`, `custom_price`, `required_roles`, `user_limit`, `user_limit_period`, `global_limit`, `global_limit_period`, `required_packages`, `has_quantity`, `is_enabled`, `created_at`, `updated_at`) VALUES
(1, 6, 'Message de connexion / déconnexion', 'Affiche un message lorsque vous êtes connecté ou déconnecté du serveur', '<p>1 Jours par point</p>', 0, 'KGiFBysVRTCCHpywcDlYacOC658Ct3aSjANumpfY.webp', 1.00, '[{\"trigger\":\"purchase\",\"require_online\":\"0\",\"commands\":[\"bonus {player} add JoinQuitMessage {quantity}\"],\"server\":\"1\"}]', NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, '[]', 1, 1, '2024-05-01 19:37:09', '2024-05-01 19:55:22'),
(2, 6, 'Aura de téléportation', 'Affiche une aura lorsque vous êtes téléporté', '<p>1 Jours par point</p>', 0, '3YYoySEyHRE96Go88s2EOZQKWEtTGuPSUqFGEme3.webp', 1.00, '[{\"trigger\":\"purchase\",\"require_online\":\"0\",\"commands\":[\"bonus {player} add AuraTP {quantity}\"],\"server\":\"1\"}]', NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, '[]', 1, 1, '2024-05-01 20:18:00', '2024-05-01 20:19:38'),
(3, 6, 'VIP', 'Devenez un VIP', '<p>1 Jours par point<br>Permet de se connecter aux serveurs même complet !</p>', 0, 'do4nC1tRZnYFmhSqRlFT6TJla2D8G9NRa8wpZYqd.webp', 1.00, '[{\"trigger\":\"purchase\",\"require_online\":\"0\",\"commands\":[\"bonus {player} add VIP {quantity}\"],\"server\":\"1\"}]', NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, '[]', 1, 1, '2024-05-01 20:20:01', '2024-05-01 20:21:19'),
(4, 6, 'VIP+', 'Devenez un VIP+', '<p>1 Jours par point<br>Permet de se connecter aux serveurs même complet !<br>Affichez votre statut VIP+ !</p>', 0, 'gU3xh3crQbvcSkez1RaC5hfy1H1SLvKSRl3AaYhZ.webp', 1.00, '[{\"trigger\":\"purchase\",\"require_online\":\"0\",\"commands\":[\"bonus {player} add VIPPlus {quantity}\"],\"server\":\"1\"}]', NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, '[]', 1, 1, '2024-05-01 20:22:05', '2024-05-01 20:23:21'),
(5, 6, 'Vol', 'Devenez un VIP+', '<p>1 Jours par point<br>Permet de voler dans les airs<br>- Dans le Spawn uniquement</p>\r\n<p>- Sur les îles SkyBlock</p>', 0, 'dN7BlGBqaEu4AsIK3LGm65gQMdn79b3jTrpYyOH8.webp', 1.00, '[{\"trigger\":\"purchase\",\"require_online\":\"0\",\"commands\":[\"bonus {player} add Fly {quantity}\"],\"server\":\"1\"}]', NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, '[]', 1, 1, '2024-05-01 20:23:30', '2024-05-01 20:25:27')
ON DUPLICATE KEY UPDATE
    `category_id` = VALUES(`category_id`),
    `name` = VALUES(`name`),
    `short_description` = VALUES(`short_description`),
    `description` = VALUES(`description`),
    `position` = VALUES(`position`),
    `image` = VALUES(`image`),
    `price` = VALUES(`price`),
    `commands` = VALUES(`commands`),
    `role_id` = VALUES(`role_id`),
    `money` = VALUES(`money`),
    `giftcard_balance` = VALUES(`giftcard_balance`),
    `custom_price` = VALUES(`custom_price`),
    `required_roles` = VALUES(`required_roles`),
    `user_limit` = VALUES(`user_limit`),
    `user_limit_period` = VALUES(`user_limit_period`),
    `global_limit` = VALUES(`global_limit`),
    `global_limit_period` = VALUES(`global_limit_period`),
    `required_packages` = VALUES(`required_packages`),
    `has_quantity` = VALUES(`has_quantity`),
    `is_enabled` = VALUES(`is_enabled`),
    `created_at` = VALUES(`created_at`),
    `updated_at` = VALUES(`updated_at`);
