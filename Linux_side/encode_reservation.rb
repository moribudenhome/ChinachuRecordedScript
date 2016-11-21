# -*- encoding: utf-8 -*-
# Chinachuで録画が終わった後エンコード待ちテーブルに叩き込むスクリプト
# 
$LOAD_PATH << __dir__
require 'active_record'
require 'yaml'
require 'json'
require 'time'
require 'net/ping'

require 'model/encode_waitings'
require 'model/wol_requests'
require 'model/series_names'

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

encode_waitings = EncodeWaitings.new()

#ARGV[0] = "/mnt/hdd/recorder/raw/raw/ＧＡＴＥ（ゲート）自衛隊　彼の地にて、斯く戦えり__22.ts"
#ARGV[1] = '{"id":"gr23608-6fo","channel":{"n":7,"type":"GR","channel":"16","name":"ＴＯＫＹＯ　ＭＸ１","id":"GR_23608","sid":"23608"},"category":"anime","title":"ＧＡＴＥ（ゲート）自衛隊　彼の地にて、斯く戦えり","subTitle":"","fullTitle":"ＧＡＴＥ（ゲート）自衛隊　彼の地にて、斯く戦えり","detail":"＃２２","episode":22,"start":1457712300000,"end":1457714100000,"seconds":1800,"flags":[],"isConflict":false,"recordedFormat":"","isSigTerm":true,"tuner":{"name":"PT3-T1","isScrambling":false,"types":["GR"],"command":"recpt1 --device /dev/pt3video2 --b25 --strip --sid <sid> <channel> - -","n":2},"recorded":"/mnt/hdd/recorder/raw/ＧＡＴＥ（ゲート）自衛隊　彼の地にて、斯く戦えり__22.ts","command":"recpt1 --device /dev/pt3video2 --b25 --strip --sid 23608 16 - -"}'

src_path = ARGV[0]
program_json = ARGV[1]
program = JSON.parse(program_json)

# エンコード元相対パス生成
path_from = Pathname(ROOT_PATH)
path_to = Pathname(ARGV[0])
src_path=path_to.relative_path_from(path_from).to_s

# エンコード完了時の名前生成
title_info = encode_waitings.encode_name(program_json)
series = title_info[:series]
title = title_info[:title]
encode_dir = ENC_BASE_DIR + series + "/"
encode_path = encode_dir + title + ".mp4"

# 出力先が無ければつくっておく
unless FileTest.exist?(ROOT_PATH + encode_dir)
  FileUtils.mkdir_p(ROOT_PATH + encode_dir) 
  FileUtils.chmod(0777,ROOT_PATH + encode_dir)
  # OSMCで時間ソートした時に下の方に出す為、空ディレクトリはタイムスタンプを遥か過去にしとく。
  File::utime(Time.at(1), Time.at(1), ROOT_PATH + encode_dir)
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
