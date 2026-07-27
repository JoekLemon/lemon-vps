<?php
$CONFIG = array (
  'overwriteprotocol' => 'https',
  'overwrite.cli.url' => getenv('NEXTCLOUD_TRUSTED_DOMAINS'),
  'trusted_proxies' => ['caddy'],

  'default_phone_region' => 'US',

  'memcache.local' => '\\OC\\Memcache\\APCu',
  'memcache.distributed' => '\\OC\\Memcache\\Memcached',

  'filelocking.enabled' => true,
  'memcache.locking' => '\\OC\\Memcache\\Redis',

  'redis' => array(
    'host' => 'redis',
    'port' => 6379,
  ),

  'maintenance_window_start' => 1,
);
