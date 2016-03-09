# -*- encoding: utf-8 -*-
# Chinachuで録画が終わった後エンコード待ちテーブルに叩き込むスクリプト
# 
$LOAD_PATH << __dir__
require 'active_record'
require 'yaml'
require 'json'
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

# レコーダーのルートパス
ROOT_PATH = conf['path']['root']
# エンコード先基底ディレクトリ
ENC_BASE_DIR = conf['path']['encode_base_dir']

#ARGV[0] = "/mnt/hdd/recorder/raw/hoge.ts"
#ARGV[1] = '{"id":"gr1040-1cil","channel":{"n":2,"type":"GR","channel":"25","name":"日テレ１","id":"GR_1040","sid":"1040"},"category":"sports","title":"サッカーアジア最強クラブ決定戦　ＡＦＣチャンピオンズリーグ２０１６ハイライト","subTitle":"","fullTitle":"サッカーアジア最強クラブ決定戦　ＡＦＣチャンピオンズリーグ２０１６ハイライト【デ】","detail":"優勝すればアジア王者の称号と共に、１２月日本開催のクラブワールドカップへの出場権が得られる大陸王者決定戦！ＦＣ東京とサンフレッチェ広島の第２節をお伝えします。","episode":2,"start":1456851840000,"end":1456855440000,"seconds":3600,"flags":["デ"],"isManualReserved":true,"isSigTerm":false,"tuner":{"name":"PT3-T1","isScrambling":false,"types":["GR"],"command":"recpt1 --device /dev/pt3video2 --b25 --strip --sid <sid> <channel> - -","n":2},"recorded":"./recorded/[160302-0204][GR25][PT3-T1]サッカーアジア最強クラブ決定戦　ＡＦＣチャンピオンズリーグ２０１６ハイライト.ts","command":"recpt1 --device /dev/pt3video2 --b25 --strip --sid 1040 25 - -"}'

src_path = ARGV[0]
program_json = ARGV[1]
program = JSON.parse(program_json)

# エンコード元相対パス生成
path_from = Pathname(ROOT_PATH)
path_to = Pathname(ARGV[0])
src_path=path_to.relative_path_from(path_from).to_s

# エンコード完了時の名前生成
encode_dir = ENC_BASE_DIR + program["title"] + "/"
encode_path = encode_dir + program["title"]
encode_path += "_" + program["subTitle"] unless program["subTitle"].blank?
encode_path += "_" + program["episode"].to_s unless program["episode"].blank?
encode_path += ".mp4"

# 出力先が無ければつくっておく
unless FileTest.exist?(ROOT_PATH + encode_dir)
  FileUtils.mkdir_p(ROOT_PATH + encode_dir) 
  FileUtils.chmod(0777,ROOT_PATH + encode_dir)
end

EncodeWaitings.new().encode_reservation(
  src_path, 
  encode_path,
  program_json
)

# 母艦PCの電源がついてなければWOLパケットを送っておく
pinger = Net::Ping::External.new(conf['encode_server']['ip_address'])
if !pinger.ping?
  WolRequests.new().wol_request(conf['encode_server']['mac_address'])
end
