require 'open-uri'
require 'nokogiri'
require 'pry'

class Crowdworks
  def scrapping
    url = "https://crowdworks.jp/public/jobs/search?keep_search_criteria=true&order=score&hide_expired=false&search%5Bkeywords%5D=rails"
    document = open(url)
    content = document.read
    parsed_content = Nokogiri::HTML(content)
  end
end
a = Crowdworks.new.scrapping