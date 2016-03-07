# -*- encoding: utf-8 -*-
# Chinachuで録画が終わった後エンコード待ちテーブルに叩き込むスクリプト
#　TODO 後々はエンコードPCのWOL辺りまでやる予定
# 
require "active_record"
require 'json'
require 'net/ping'

# DB接続設定
ActiveRecord::Base.establish_connection(
  adapter:  "mysql2",
  host:     "localhost",
  username: "root",
  password: "",
  database: "chinachu_manage",
)

# テーブルにアクセスするためのクラスを宣言
class EncodeWaitings < ActiveRecord::Base
  # テーブル名が命名規則に沿わない場合、
  # self.table_name = 'encode_waitings'  # set_table_nameは古いから注意
  enum encode_state: %i(wait progress success failure)
end

class WolRequests < ActiveRecord::Base
  enum wol_state: %i(requested success)
end

# レコーダーのルートパス
ROOT_PATH = "/mnt/hdd/recorder/"
# エンコード先基底ディレクトリ
ENC_BASE_DIR = "enc/"

# 相対パスへ変換
def to_relative_path(path)
	path_from = Pathname(ROOT_PATH)
	path_to = Pathname(path)
	path_to.relative_path_from(path_from).to_s
end

# tsの保存先 TODO 後でコマンドライン引数から持ってくる
#src_path = "/mnt/hdd/recorder/raw/hoge.ts"
src_path = ARGV[0]
#program_json = '{"id":"gr1040-1cil","channel":{"n":2,"type":"GR","channel":"25","name":"日テレ１","id":"GR_1040","sid":"1040"},"category":"sports","title":"サッカーアジア最強クラブ決定戦　ＡＦＣチャンピオンズリーグ２０１６ハイライト","subTitle":"","fullTitle":"サッカーアジア最強クラブ決定戦　ＡＦＣチャンピオンズリーグ２０１６ハイライト【デ】","detail":"優勝すればアジア王者の称号と共に、１２月日本開催のクラブワールドカップへの出場権が得られる大陸王者決定戦！ＦＣ東京とサンフレッチェ広島の第２節をお伝えします。","episode":2,"start":1456851840000,"end":1456855440000,"seconds":3600,"flags":["デ"],"isManualReserved":true,"isSigTerm":false,"tuner":{"name":"PT3-T1","isScrambling":false,"types":["GR"],"command":"recpt1 --device /dev/pt3video2 --b25 --strip --sid <sid> <channel> - -","n":2},"recorded":"./recorded/[160302-0204][GR25][PT3-T1]サッカーアジア最強クラブ決定戦　ＡＦＣチャンピオンズリーグ２０１６ハイライト.ts","command":"recpt1 --device /dev/pt3video2 --b25 --strip --sid 1040 25 - -"}'
program_json = ARGV[1]
program = JSON.parse(program_json)

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

EncodeWaitings.create(
	:src_path => to_relative_path(src_path), 
	:dst_path => encode_path, 
	:program_data => program_json, 
	:encode_state => EncodeWaitings.encode_states[:wait])

# 母艦PCの電源がついてなければWOLパケットを送っておく
pinger = Net::Ping::External.new('192.168.1.2')
if !pinger.ping?
  system( "sudo ether-wake -b 74:D4:35:87:0A:03" )
  system( "sudo ether-wake -b 74:D4:35:87:0A:03" )
  system( "sudo ether-wake -b 74:D4:35:87:0A:03" )
  WolRequests.create( :wol_state => WolRequests.wol_states[:requested]
end