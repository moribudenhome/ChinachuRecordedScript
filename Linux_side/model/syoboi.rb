require 'net/http'

class Syoboi
  CHANNEL = JSON.load(File.read(File.dirname(File.expand_path(__FILE__)) + "/../json/channel.json"))
  def program_title(chanel,start,_end)
    start_time = Time.at(start)
    end_time = Time.at(_end)
    json = Net::HTTP.get (URI.parse("http://cal.syoboi.jp/rss2.php?start=#{start_time.strftime('%Y%m%d%H%M')}&end=#{end_time.strftime('%Y%m%d%H%M')}&usr=moribuden_666&alt=json"))
    if JSON.load(json)['items'].each { |program|
        if program['ChName'] == CHANNEL[chanel][0] 
          #p "#{program['Title']}_#{program['Count']}"
          return nil if program['Title'].blank? || program['Count'].blank?
          return { :title => program['Title'], :count => program['Count'] }
        end
      }
    end
  end
end