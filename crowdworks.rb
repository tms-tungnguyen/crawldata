# Ruby version 2.7.3
require 'open-uri'
require 'nokogiri'
require 'writeexcel'
require 'pry'

class Crowdworks

  def scrapping(keyword, filter)
    page = last_page(keyword, filter, number = 1)
    i = 1
    user = []
    title = []
    url = []
    data = {}
    while i <= page
      root_path = "https://crowdworks.jp/public/jobs/search?hide_expired=#{filter}&keep_search_criteria=true&order=score&page=#{i}&search%5Bkeywords%5D=#{keyword}"
      document = open(root_path)
      content = document.read
      parsed_content = Nokogiri::HTML(content)
      response = parsed_content.xpath("//h3[@class='item_title']").to_a
      response_user = parsed_content.xpath("//span[@class='user-name']").to_a

      user[i-1] = fetch_user(response_user)
      title[i-1] = fetch_title(response)
      url[i-1] = fetch_url(response)
      i += 1
    end
    data = { user: user.flatten, title: title.flatten, url: url.flatten }
    save_data_jobs(data, keyword, filter)
  end

  def last_page(keyword, filter, number)
    url = "https://crowdworks.jp/public/jobs/search?hide_expired=#{filter}&keep_search_criteria=true&order=score&page=#{number}&search%5Bkeywords%5D=#{keyword}"
    document = open(url)
    content = document.read
    parsed_content = Nokogiri::HTML(content)

    if next_page?(parsed_content)
      number = parsed_content.xpath("//div[@class='pagination_body']").children.to_a.last.children.text.to_i
      last_page(keyword, filter, number)
    else
      parsed_content.xpath("//div[@class='pagination_body']").children.to_a.last.children.text.to_i
    end
  rescue
    0
  end

  def next_page?(parsed_content)
    !parsed_content.xpath("//div/a[@class='to_next_page']").empty?
  end

  def fetch_title(response)
    title = []
    response.each do |res|
      title << res.children.text.gsub!(/\s+/, '')
    end
    title
  end

  def fetch_url(response)
    url = []
    response.each do |res|
      url << "https://crowdworks.jp/#{res.children.to_a[1].to_h['href']}"
    end
    url
  end

  def fetch_user(response_user)
    user = []
    response_user.each do |res|
      user << res.children.text.gsub!(/\s+/, '')
    end
    user
  end

  def save_data_jobs(data, keyword, filter)
    column = 0
    workbook  = WriteExcel.new("#{Time.now.strftime("%d-%m-%Y-%H-%M-%S")}-#{keyword}-#{filter == 'true' ? 'unexpired' : 'all'}.xls")
    worksheet = workbook.add_worksheet
    data.map do |key, values|
      values.each_with_index do |dt, index|
        if column != 2
          worksheet.write_string(index, column, dt)
        else
          worksheet.write_url(index, column, dt)
        end
      end
      column += 1
    end
    workbook.close
  end
end

# filter: all = false // unexpired = true
# keyword: rails
scrapping = Crowdworks.new.scrapping('rails', 'true')

# Run: ruby crowdworks.rb