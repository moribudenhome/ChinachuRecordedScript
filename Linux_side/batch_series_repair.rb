$LOAD_PATH << __dir__
require 'active_record'
require 'yaml'
require "moji"

require 'model/encode_waitings'
require 'model/series_names'
require 'model/syoboi'

# 設定ファイル読み込み
conf = YAML.load_file(__dir__+'/yaml/configs.yml')
# DB接続
ActiveRecord::Base.establish_connection(conf['db'])

# これ設定しとかないとタイムゾーンがずれまくる
Time.zone_default =  Time.find_zone! 'Tokyo'
ActiveRecord::Base.default_timezone = :local

encode_waitings = EncodeWaitings.new()
syoboi = Syoboi.new()

i = 0
EncodeWaitings.where(
    encode_state: EncodeWaitings.encode_states[:clean_up]
  ).map{ |rec|
  p '--------------------------'
  series_name = ""
  rename_title = ""

  program_data = JSON.load(rec.program_data)

  # レコーダーのルートパス
  root_path = conf['path']['root']
  # エンコード先基底ディレクトリ
  enc_base_dir = File::split(File::dirname(rec.dst_path))[0] + '/'
  p 'root_path='+root_path
  p 'enc_base_dir='+enc_base_dir
  #next
  # シリーズ定義テーブルから該当のシリーズ名取得
  SeriesNames.all.map{ |name|
    if program_data['title'].include?(name.name)
      series_name =  Moji.han_to_zen(name.name)
      rename_title = File::basename(rec.src_path,'.ts') + '.mp4'
    end
  }

  # しょぼいカレンダーからタイトル情報取得
  # ※しょぼいの方に有ればそっちが優先
  channel_name = program_data['channel']['type'] + program_data['channel']['channel']
  title_info = syoboi.program_title(
    channel_name,
    program_data['start'].to_i/1000,
    program_data['end'].to_i/1000
  )
  unless title_info.nil?
    series_name = Moji.han_to_zen(title_info[:title])
    rename_title = "#{series_name}_#{title_info[:count]}.mp4"
  end

  # ここまで来てデータもまともじゃなかったらいろいろあきらめて未分類へ
  if series_name.empty?
    series_name = 'unknown'
  end
  if rename_title.empty?
    rename_title = File::basename(rec.src_path,'.ts') + '.mp4'
  end

  # 各種変更が必要かチェック
  if 
    File::dirname(rec.dst_path) == enc_base_dir + series_name &&
    rename_title == File::basename(rec.dst_path)
    p 'no touch : ' + rec.dst_path
    p '--------------------------'
    next
  end

  new_dst_path = enc_base_dir + series_name + "/" + rename_title
  new_encode_dir = root_path + enc_base_dir + series_name

  p 'new_encode_dir : '+ new_encode_dir
  p rec.dst_path + ' -> ' + new_dst_path

  # 出力先が無ければつくっておく
  unless FileTest.exist?(new_encode_dir)
    p 'create directory : ' + new_encode_dir
    FileUtils.mkdir_p(new_encode_dir) 
    FileUtils.chmod(0777,new_encode_dir)
    # OSMCで時間ソートした時に下の方に出す為、空ディレクトリはタイムスタンプを遥か過去にしとく。
    File::utime(Time.at(1), Time.at(1), new_encode_dir)
  end
  # 移動先が既に存在していないか
  if FileTest.exist?(root_path + new_dst_path)
    p 'file exist : '+ root_path + new_dst_path
    p '--------------------------'
    next
  end
  # 移動元が存在するか
  unless FileTest.exist?(root_path + rec.dst_path)
    p 'not found src file: ' + root_path + rec.dst_path
    next
  end
  p 'file　move : ' + root_path + rec.dst_path + ' ->  ' + root_path + new_dst_path
  unless FileUtils.move(root_path + rec.dst_path, root_path + new_dst_path)
    p 'file move Failure : '+ root_path + rec.dst_path + ' ->  ' + root_path + new_dst_path
    p '--------------------------'
    next
  end
  p '--------------------------'
#  symlink_name = File.basename(rec.src_path)
#  p RAW_PATH+symlink_name
#  FileUtils.remove(RAW_PATH+symlink_name)
#  File.symlink(root_path + new_dst_path, RAW_PATH+symlink_name)


#  begin
#    Dir.rmdir(root_path+File::dirname(rec.dst_path))
#  rescue
#  end

  rec.dst_path = new_dst_path
  rec.save!
#  break if 10 < i 
#  i+=1
}
