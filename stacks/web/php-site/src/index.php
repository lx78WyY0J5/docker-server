<?php
declare(strict_types=1);

$dbStatus = 'non configurée';
$dbDetails = '';

$host = getenv('DB_HOST');
if ($host !== false && $host !== '') {
    $dsn = sprintf(
        'mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
        $host,
        getenv('DB_PORT') ?: '3306',
        getenv('DB_NAME') ?: ''
    );

    try {
        $pdo = new PDO($dsn, getenv('DB_USER') ?: '', getenv('DB_PASSWORD') ?: '', [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_TIMEOUT => 5,
        ]);
        $version = $pdo->query('SELECT VERSION()')->fetchColumn();
        $dbStatus = 'connectée';
        $dbDetails = 'MariaDB ' . $version;
    } catch (Throwable $e) {
        $dbStatus = 'indisponible';
        $dbDetails = $e->getMessage();
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Altherneum — site PHP</title>
    <style>
        :root { color-scheme: light dark; }
        body { font-family: system-ui, sans-serif; max-width: 42rem; margin: 4rem auto; padding: 0 1rem; line-height: 1.6; }
        code { padding: .15rem .35rem; border-radius: .25rem; background: rgba(127,127,127,.18); }
        .ok { color: #178a4b; }
        .ko { color: #b42318; }
    </style>
</head>
<body>
    <h1>Altherneum — site PHP</h1>
    <p>Cette page remplace l'ancien <code>phpdoc.altherneum.fr</code>.</p>

    <h2>État du service</h2>
    <ul>
        <li>PHP : <?= htmlspecialchars(PHP_VERSION, ENT_QUOTES, 'UTF-8') ?></li>
        <li>Base de données : <strong class="<?= $dbStatus === 'connectée' ? 'ok' : 'ko' ?>"><?= htmlspecialchars($dbStatus, ENT_QUOTES, 'UTF-8') ?></strong>
            <?php if ($dbDetails !== ''): ?>
                — <?= htmlspecialchars($dbDetails, ENT_QUOTES, 'UTF-8') ?>
            <?php endif; ?>
        </li>
    </ul>

    <p>Déposez votre application dans <code>stacks/web/php-site/src/</code>.</p>
</body>
</html>
