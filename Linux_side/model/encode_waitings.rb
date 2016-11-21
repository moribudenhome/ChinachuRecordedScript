require "moji"
require "model/syoboi"

class EncodeWaitings < ActiveRecord::Base
  enum encode_state: %i(wait progress success failure clean_up)

  def exists_encode_wait?
    EncodeWaitings.exists?(:encode_state => EncodeWaitings.encode_states[:wait])
  end

  def exists_encode_progress?
    EncodeWaitings.exists?(:encode_state => EncodeWaitings.encode_states[:progress])
  end

  def encode_reservation(src_path, dest_path, program_json)
    EncodeWaitings.create(
    :src_path => src_path, 
    :dst_path => dest_path, 
    :program_data => program_json, 
    :encode_state => EncodeWaitings.encode_states[:wait])
  end

  def encode_name(program_json)
    series_name = ""
    title = ""
    program_data = JSON.load(program_json)

    # シリーズ定義テーブルから該当のシリーズ名取得
    SeriesNames.all.map{ |name|
      if program_data['title'].include?(name.name)
        series_name =  Moji.han_to_zen(name.name)
        title = File::basename(program_data['recorded'],'.ts')
      end
    }

    # しょぼいカレンダーからタイトル情報取得
    # ※しょぼいの方に有ればそっちが優先
    channel_name = program_data['channel']['type'] + program_data['channel']['channel']
    title_info = Syoboi.new().program_title(
      channel_name,
      program_data['start'].to_i/1000,
      program_data['end'].to_i/1000
    )

    unless title_info.nil?
      series_name = Moji.han_to_zen(title_info[:title])
      title = "#{series_name}_#{title_info[:count]}"
    end

    # ここまで来てデータもまともじゃなかったらいろいろあきらめて未分類へ
    if series_name.empty?
      series_name = 'unknown'
    end
    if title.empty?
      title = File::basename(program_data['recorded'],'.ts')
    end
    return { :series => series_name, :title => title }
  end
end
