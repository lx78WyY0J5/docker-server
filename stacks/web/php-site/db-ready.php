<?php
// Vérifie que la base du site PHP contient bien le schéma initial.
// Utilisé par l'entrypoint avant de lancer Apache.
$_SERVER['DOCUMENT_ROOT'] = '/var/www/html/public';
require_once $_SERVER['DOCUMENT_ROOT'] . '/src/php/loadEnv.php';

$host = getenv('DB_IP');
$db = getenv('DB_NAME');
$user = getenv('DB_USER');
$pass = getenv('DB_PASS');

try {
    $pdo = new PDO(
        sprintf('mysql:host=%s;dbname=%s;charset=utf8mb4', $host, $db),
        $user,
        $pass,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    $table = $pdo->query("SHOW TABLES LIKE 'users'")->fetchColumn();
    exit($table === false ? 1 : 0);
} catch (Throwable $e) {
    fwrite(STDERR, 'Base du site indisponible : ' . $e->getMessage() . PHP_EOL);
    exit(1);
}
