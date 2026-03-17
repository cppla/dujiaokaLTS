<?php

namespace App\Jobs;

use App\Models\Order;
use GuzzleHttp\Client;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class ApiHook implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    /**
     * 任务最大尝试次数。
     *
     * @var int
     */
    public $tries = 2;

    /**
     * 任务运行的超时时间。
     *
     * @var int
     */
    public $timeout = 30;

    /**
     * @var Order
     */
    private $order;

    /**
     * 商品服务层.
     * @var \App\Service\PayService
     */
    private $goodsService;


    /**
     * Create a new job instance.
     *
     * @return void
     */
    public function __construct(Order $order)
    {
        $this->order = $order;
        $this->goodsService = app('Service\GoodsService');
    }

    /**
     * Execute the job.
     *
     * @return void
     */
    public function handle()
    {
        $goodInfo = $this->goodsService->detail($this->order->goods_id);
        // 判断是否有配置支付回调
        if(empty($goodInfo->api_hook)){
            return;
        }
        if (!$this->isSafeHookUrl($goodInfo->api_hook)) {
            return;
        }
        $postdata = [
            'title' => $this->order->title,
            'order_sn' => $this->order->order_sn,
            'email' => $this->order->email,
            'actual_price' => $this->order->actual_price,
            'order_info' => $this->order->info,
            'good_id' => $goodInfo->id,
            'gd_name' => $goodInfo->gd_name

        ];

        $client = new Client([
            'timeout' => 5,
            'allow_redirects' => false,
        ]);

        try {
            $client->post($goodInfo->api_hook, [
                'headers' => [
                    'Content-Type' => 'application/json',
                ],
                'body' => json_encode($postdata, JSON_UNESCAPED_UNICODE),
            ]);
        } catch (\Throwable $exception) {
        }
    }

    private function isSafeHookUrl(string $url): bool
    {
        $parts = parse_url($url);
        if (!$parts || empty($parts['scheme']) || empty($parts['host'])) {
            return false;
        }

        if (!in_array(strtolower($parts['scheme']), ['http', 'https'], true)) {
            return false;
        }

        $host = $parts['host'];
        $ips = gethostbynamel($host);
        if ($ips === false || empty($ips)) {
            return false;
        }

        foreach ($ips as $ip) {
            if (!filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE)) {
                return false;
            }
        }

        return true;
    }
}
