<?php

namespace App\Http\Middleware;

use Fideloper\Proxy\TrustProxies as Middleware;
use Illuminate\Http\Request;

class TrustProxies extends Middleware
{
    /**
     * The trusted proxies for this application.
     *
     * Trusting all proxies ('*') is appropriate when the application runs behind a
     * controlled reverse-proxy (e.g. Nginx on the same host/Docker network) and the
     * proxy IP cannot be predicted at deploy time. If you know the proxy's IP, replace
     * '*' with that specific address for stricter control.
     *
     * @var array|string
     */
    protected $proxies = '*';

    /**
     * The headers that should be used to detect proxies.
     *
     * @var int
     */
    protected $headers = Request::HEADER_X_FORWARDED_ALL;
}
