SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

INSERT INTO `settings` (`name`, `value`) VALUES
('copyright', 'Copyright © 2026 ${DOMAIN_NAME} - Tous droits réservés.'),
('money', 'points'),
('register', '0'),
('name', '${DOMAIN_NAME}${TLD}'),
('url', 'https://play.${DOMAIN_NAME}${TLD}'),
('timezone', 'UTC'),
('locale', 'fr'),
('users.money_transfer', '1'),
('keywords', 'Serveur, Minecraft, SkyBlock, RPG, OP-Prison, Survie, Anarchie'),
('icon', 'icone.png'),
('logo', 'icone.png'),
('background', 'background.jpg'),
('description', 'Serveurs open source, rejoins-nous sur un Skyblock, OP-Prison, Anarchie, ... faits maison !'),
('mail.from.address', 'mail@${DOMAIN_NAME}${TLD}'),
('mail.mailer', 'sendmail'),
('mail.smtp.host', 'mailhog'),
('mail.smtp.port', '1025'),
('mail.users_email_verification', '1'),
('servers.default', '1'),
('theme', 'prism'),
('themes.config.prism', '{\"color\":\"#c0392b\",\"title\":\"Bienvenue sur les serveurs de jeux ${DOMAIN_NAME}${TLD}\",\"footer_description\":\"Serveurs Minecraft open source, rejoins-nous sur un Skyblock, OP-Prison, Anarchie, ... faits maison !\",\"footer_links\":[{\"name\":\"Documentation\",\"value\":\"https:\\/\\/doc.${DOMAIN_NAME}${TLD}\"},{\"name\":\"Librairies externes\",\"value\":\"https:\\/\\/doc.${DOMAIN_NAME}${TLD}\\/github\\/readme#Libs-externes\"},{\"name\":\"Discord\",\"value\":\"https:\\/\\/discord.${DOMAIN_NAME}${TLD}\"},{\"name\":\"Github\",\"value\":\"https:\\/\\/github.${DOMAIN_NAME}${TLD}\"}]}'),
('currency', 'EUR'),
('shop.use_site_money', '1'),
('shop.month_goal', '5'),
('shop.recent_payments', '10'),
('shop.top_customer', '1'),
('shop.display_amount', '1'),
('shop.home.enabled', '1'),
('shop.home', '<p>Bienvenue sur la <span style=\"text-decoration: underline;\"><strong>boutique des serveurs de jeux d\'${DOMAIN_NAME}</strong></span> !<br><br>Le serveur est <strong>farm to win</strong>. La boutique contient donc <span style=\"text-decoration: underline;\"><strong>uniquement des cosmétiques,</strong></span> achetable aussi via l\'argent en jeu (Gold)</p>')
ON DUPLICATE KEY UPDATE
    `value` = VALUES(`value`);
