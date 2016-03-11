####
# エンコード予約リストに書き込むのに失敗した動画を再度リストに加える
$LOAD_PATH << __dir__
require 'active_record'
require 'yaml'
require 'net/http'
require 'net/ping'
require 'uri'

require 'model/encode_waitings'

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


# 録画済みリストを取得
end_point = 'api/recorded.json';
req = Net::HTTP::Get.new('/api/recorded.json')
req.basic_auth('akari', 'bakuhatsu')
Net::HTTP.start('192.168.1.6', 10772) {|http|
  recorded = JSON.parse(http.request(req).body)
  recorded.each {|e|
    name = e['recorded']
    ext = File.extname(name)
    if ext == '.ts'
      # .tsの場合は未エンコードなのでエンコード待ちリストに存在しているか確認
      path_from = Pathname(ROOT_PATH)
      path_to = Pathname(name)
      src_path=path_to.relative_path_from(path_from).to_s
      next if EncodeWaitings.exists?(:src_path => src_path)

      # 存在していない時はエンコード済みファイルの存在確認
      encode_dir = ENC_BASE_DIR + e["title"] + "/"
      encode_path = encode_dir + e["title"]
      encode_path += "_" + e["subTitle"] unless e["subTitle"].blank?
      encode_path += "_" + e["episode"].to_s unless e["episode"].blank?
      encode_path += ".mp4"
      next if FileTest.exist?(ROOT_PATH + encode_path)

      # どうやらエンコード待ちリストにも無いしエンコードもされていないみたいなのでエンコード待ちに加える
      # 出力先が無ければつくっておく
      unless FileTest.exist?(ROOT_PATH + encode_dir)
        FileUtils.mkdir_p(ROOT_PATH + encode_dir) 
        FileUtils.chmod(0777,ROOT_PATH + encode_dir)
        # OSMCで時間ソートした時に下の方に出す為、空ディレクトリはタイムスタンプを遥か過去にしとく。
        File::utime(Time.at(1), Time.at(1), ROOT_PATH + encode_dir)
      end
      # 予約
      EncodeWaitings.new().encode_reservation(
        src_path, 
        encode_path,
        JSON.pretty_generate(e)
      )
      p name + 'がエンコード待ちリストに入ってないようなので追加しました。'
    end
  }
}