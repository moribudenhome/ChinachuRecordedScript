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

encode_waitings = EncodeWaitings.new()
wol_request = WolRequests.new()

# エンコード待ちが溜まっていたらエンコードサーバーの電源を入れる
if encode_waitings.exists_encode_wait?
  pinger = Net::Ping::External.new(conf['encode_server']['ip_address'])
  if !pinger.ping?
    wol_request.wol_request(conf['encode_server']['mac_address'])
  end
end

# エンコード中に強制的に中断されたと思われる予約が有るときもサーバーの電源いれる
if encode_waitings.exists_encode_progress?
  pinger = Net::Ping::External.new(conf['encode_server']['ip_address'])
  if !pinger.ping?  
    EncodeWaitings.where(
      encode_state: EncodeWaitings.encode_states[:progress]).each {|rec|
      p rec.id
      rec.encode_state = EncodeWaitings.encode_states[:wait]
    }
    WolRequests.new().wol_request(conf['encode_server']['mac_address'])
  end
end
