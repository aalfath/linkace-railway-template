<?php
// Exit 0: database and Redis reachable, LinkAce tables exist.
// Exit 3: reachable, database empty (first run, setup wizard pending).
// Exit 1: not reachable yet.
try {
    require '/app/vendor/autoload.php';
    $app = require '/app/bootstrap/app.php';
    $app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
    Illuminate\Support\Facades\Redis::connection()->ping();
    exit(Illuminate\Support\Facades\Schema::hasTable('migrations') ? 0 : 3);
} catch (Throwable $e) {
    fwrite(STDERR, 'not ready: ' . substr($e->getMessage(), 0, 200) . PHP_EOL);
    exit(1);
}
