SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

INSERT INTO `social_links` (`id`, `type`, `value`, `position`, `properties`, `created_at`, `updated_at`) VALUES
(1, 'twitter', 'https://twitter.com/${DOMAIN_NAME}${TLD}', 1, NULL, '2024-04-27 14:58:41', '2024-04-27 16:09:50'),
(2, 'youtube', 'https://Youtube.com/@${DOMAIN_NAME}${TLD}', 2, NULL, '2024-04-27 14:58:41', '2024-04-27 16:09:50'),
(3, 'discord', 'https://discord.${DOMAIN_NAME}${TLD}', 0, NULL, '2024-04-27 16:14:26', '2026-06-07 22:30:09'),
(4, 'other', 'https://doc.${DOMAIN_NAME}${TLD}', 0, '{\"title\":\"Documentation\",\"icon\":\"bi bi-book\",\"color\":\"#2196f3\"}', '2024-04-27 16:15:08', '2024-04-27 16:15:08')
ON DUPLICATE KEY UPDATE
    `type` = VALUES(`type`),
    `value` = VALUES(`value`),
    `position` = VALUES(`position`),
    `properties` = VALUES(`properties`),
    `created_at` = VALUES(`created_at`),
    `updated_at` = VALUES(`updated_at`);
