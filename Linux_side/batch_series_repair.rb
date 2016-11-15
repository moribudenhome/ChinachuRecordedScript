$LOAD_PATH << __dir__
require 'active_record'
require 'yaml'

require 'model/encode_waitings'
require 'model/series_names'

# 設定ファイル読み込み
conf = YAML.load_file(__dir__+'/yaml/configs.yml')
# DB接続
ActiveRecord::Base.establish_connection(conf['db'])

# これ設定しとかないとタイムゾーンがずれまくる
Time.zone_default =  Time.find_zone! 'Tokyo'
ActiveRecord::Base.default_timezone = :local

encode_waitings = EncodeWaitings.new()

# レコーダーのルートパス
ROOT_PATH = conf['path']['root']
# エンコード先基底ディレクトリ
ENC_BASE_DIR = conf['path']['encode_base_dir']
# 生ファイルディレクトリ
RAW_PATH = ROOT_PATH + conf['path']['raw_base_dir']

i = 0
#=begin
EncodeWaitings.where(
    encode_state: EncodeWaitings.encode_states[:clean_up]
  ).map{ |rec|
  series_name = ""
  SeriesNames.all.map{ |name|
    if File::dirname(rec.dst_path).include?(name.name)
      series_name =  name.name
    end
  }
  # シリーズ定義テーブル内に存在しなければ処理しない
  next if series_name.empty?
  # すでにシリーズディレクトが指定されている
  next if File::dirname(rec.dst_path) == ENC_BASE_DIR + series_name
  p series_name
  new_dst_path = ENC_BASE_DIR + series_name + "/" + File::basename(rec.dst_path)
  new_encode_dir = ROOT_PATH + File::dirname(new_dst_path)

  # 出力先が無ければつくっておく
  unless FileTest.exist?(new_encode_dir)
    FileUtils.mkdir_p(new_encode_dir) 
    FileUtils.chmod(0777,new_encode_dir)
    # OSMCで時間ソートした時に下の方に出す為、空ディレクトリはタイムスタンプを遥か過去にしとく。
    File::utime(Time.at(1), Time.at(1), new_encode_dir)
  end
#=begin
  if FileTest.exist?(ROOT_PATH + rec.dst_path)
    next unless FileUtils.move(ROOT_PATH + rec.dst_path, ROOT_PATH + new_dst_path)
  end
  symlink_name = File.basename(rec.src_path)
  # p RAW_PATH+symlink_name
  #if FileTest.exist?(RAW_PATH+symlink_name)
    p RAW_PATH+symlink_name
    FileUtils.remove(RAW_PATH+symlink_name)
  #end
  File.symlink(ROOT_PATH + new_dst_path, RAW_PATH+symlink_name)
  #File::utime(Time.at(1), Time.at(1), ROOT_PATH + File::dirname(rec.dst_path))

  begin
    Dir.rmdir(ROOT_PATH+File::dirname(rec.dst_path))
  rescue
  end

  rec.dst_path = new_dst_path
  rec.save!


  #i = i + 1
  #break if 5 < i
  #p series_name
  #p File::dirname(ROOT_PATH+e.dst_path)
#=end
}
#p i
=begin
$LOAD_PATH << __dir__
require 'diff/lcs'

file_names = []
Dir::entries("/mnt/hdd/recorder/enc").map { |name|
  if name != "." && name != ".."
    file_names.push(name)
  end
}

#file_names = ["田中くんはいつもけだるげ",
#              "田中くんはいつもけだるげ　「ギャップ少女越前さん」",
#              "田中くんはいつもけだるげ　「田中くんの日常」",
#              "田中くんはいつもけだるげ　「白石さんの秘密」"]


file_names.sort!

work_file_names = []
(0..file_names.size-1).map{ |i|
  str = ""
  prev_size = (0 <= i - 1) ? file_names[i - 1].size : 0 
  next_size = (i + 1 < file_names.size) ? file_names[i + 1].size : 0
  is_all_match = true
  (0..file_names[i].size - 1).map { |j|
      is_hit = false
      if prev_size > j && 0 <= i - 1 && file_names[i][j] == file_names[i - 1][j] 
        is_hit = true
      end
      if next_size > j && i + 1 < file_names.size && file_names[i][j] == file_names[i + 1][j]
        is_hit = true
      end
      if is_hit
        str += file_names[i][j]
      else
        is_all_match = false
        str.gsub!(/( |　|「|【|（|『)+$/, "")
        if !work_file_names.include?(str)
          work_file_names.push(str)
          #p str
        end
        break
      end
  }
  if is_all_match
    str.gsub!(/( |　|「|【|（|『)+$/, "")
    if !work_file_names.include?(str)
      work_file_names.push(str)
      #p str
    end
  end
}
file_names = work_file_names

file_names.reverse_each do |name|
  if name.size < 2
    file_names.delete(name)
  end
end

file_names.each do |name|
  p name
end



seq1 = "ハピネスチャージプリキュア！_アクシアの真の姿！シャイニングメイクドレッサー！！_29.ts"
seq2 = "ハピネスチャージプリキュア！_いおなの初恋！？イノセントフォーム発動！_32_[gr23608-de9].ts"

lcs = Diff::LCS.LCS(seq1, seq2)
diffs = Diff::LCS.diff(seq1, seq2)
sdiff = Diff::LCS.sdiff(seq1, seq2)

#p lcs
#p diffs
#p sdiff
=end
=begin
  
rescue Exception => e
  
end
work = []
sdiff.map do |elem|
  if Array(elem)[0] == "="
    work.push( [Array(Array(elem)[1]), Array(Array(elem)[2])] )
    #p Array(Array(elem)[1])
  end
end
work2 = []

p work
p ""
p ""

i = -1
j = -1
str = "";
work.map do |elem|
  if i == -1 || j == -1
    i = elem[0][0]
    j = elem[1][0]
    str = elem[0][1]
  elsif i + 1 == elem[0][0] && j + 1 == elem[1][0] && elem[0][1] == elem[1][1]
    i+=1
    j+=1
    str += elem[0][1]
  else
    p str
    i = elem[0][0]
    j = elem[1][0]
    str = elem[0][1]
  end
end
p str
=end