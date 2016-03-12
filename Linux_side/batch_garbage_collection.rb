$LOAD_PATH << __dir__
require 'active_record'
require 'yaml'
require 'streamio-ffmpeg'

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
# ゴミ箱ディレクトリ
TRASH_PATH = ROOT_PATH + conf['path']['trash_base_dir']
# 生ファイルディレクトリ
RAW_PATH = ROOT_PATH + conf['path']['raw_base_dir']

# エンコード成功状態の物が本当に成功しているかチェック
EncodeWaitings.where(
    encode_state: EncodeWaitings.encode_states[:success]
  ).each do |rec|
  src_path = ROOT_PATH + rec.src_path
  dst_path = ROOT_PATH + rec.dst_path
  if !FileTest.exist?(dst_path)
    if !FileTest.exist?(src_path)
      p "失敗なうえに元ファイルも消えてる: "+rec.dst_path
      # 恐らく動画自体が削除された。clean_up済み扱いへ
      rec.encode_state = EncodeWaitings.encode_states[:clean_up]
    else
      p "失敗というかエンコードされた形跡無いけど元ファイルは有る: "+rec.dst_path
      # 起きうる状態が想像つかないがとりあえず再エンコード依頼
      rec.encode_state = EncodeWaitings.encode_states[:wait]
    end
  elsif !FFMPEG::Movie.new(dst_path).valid?
     p "エンコード失敗: "+rec.dst_path
     # 失敗扱いにする
     rec.encode_state = EncodeWaitings.encode_states[:failure]
  else
    begin
      next unless FileUtils.move(src_path, TRASH_PATH)
      symlink_name = File.basename(src_path);
      File.symlink(dst_path, RAW_PATH+symlink_name)
      rec.encode_state = EncodeWaitings.encode_states[:clean_up]
      p "成功: "+rec.dst_path
    rescue
      next
    end
  end
  rec.save
end
