<?php
// Initialisation CLI du schéma du site PHP.
// Le script create-db.php du site exige une session admin (ou LOCAL/FIRST_RUN).
$_SERVER['DOCUMENT_ROOT'] = '/var/www/html/public';
$_SESSION = ['is_admin' => true];

require $_SERVER['DOCUMENT_ROOT'] . '/src/php/create-db.php';
