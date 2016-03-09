$LOAD_PATH << __dir__
require 'active_record'
require 'yaml'
require 'net/ping'

require 'model/encode_waitings'
require 'model/wol_requests'

# 設定ファイル読み込み
conf = YAML.load_file(__dir__+'/yaml/configs.yml')
# DB接続
ActiveRecord::Base.establish_connection(conf['db'])

# これ設定しとかないとタイムゾーンがずれまくる
Time.zone_default =  Time.find_zone! 'Tokyo'
ActiveRecord::Base.default_timezone = :local

if EncodeWaitings.new().exists_encode_wait?
  pinger = Net::Ping::External.new(conf['encode_server']['ip_address'])
  if !pinger.ping?
    WolRequests.new().wol_request(conf['encode_server']['mac_address'])
  end
end

