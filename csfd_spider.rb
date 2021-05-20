require 'kimurai'

class CsfdSpider < Kimurai::Base
  @name = 'csfd_spider'
  @engine = :selenium_chrome
  @start_urls = ['https://www.csfd.cz/zebricky/vlastni-vyber/']
  @config = {}

  def parse(response, url:, data: {})
    browser.click_button 'Rozumím a přijímám'
    browser.find(:xpath, "//div[@id='genres-content']/a").click
    browser.find(:xpath, "//span[.='Fantasy']/preceding::input[1]").click
    browser.click_button 'Zobrazit'

    response = browser.current_response

    response.xpath("//a[@class='film-title-name']").each do |a|
      request_to :parse_movie_page, url: absolute_url(a[:href], base: url)
    end

    # next_page = response.at_xpath("//a[@class='next_page']")
    #
    # if next_page.present?
    #   request_to :parse, url: absolute_url(next_page[:href], base: url)
    # end
  end

  def parse_movie_page(response, url:, data: {})
    @response = response
    item = {}

    item[:title] = @response
      .xpath("//h1")
      .text
      .strip

    item[:genres] = @response
      .xpath("//div[@class='genres']")
      .text
      .split(' / ')

    item[:origin] = @response
      .xpath("//div[@class='origin']")
      .text
      .split(',')
      .first
      .split(' / ')

    item[:year] = @response
      .xpath("//span[@itemprop='dateCreated']")
      .text
      .strip

    item[:rating_value] = @response
      .xpath("//meta[@itemprop='ratingValue']")
      .attribute('content')

    item[:rating_count] = @response
      .xpath("//meta[@itemprop='ratingCount']")
      .attribute('content')

    item[:review_count] = @response
      .xpath("//meta[@itemprop='reviewCount']")
      .attribute('content')

    item[:based_on] = @response
      .xpath("//h4[.='Předloha: ']/following::span[1]/a")
      .text
      .strip

    item[:directors] = loop_to_array(
      "//h4[.='Režie: ']/following::span[1]/a | " +
      "//h4[.='Režie: ']/following::span[1]/span[1]/a"
    )

    item[:scenarists] = loop_to_array(
      "//h4[.='Scénář: ']/following::span[1]/a |" +
      "//h4[.='Scénář: ']/following::span[1]/span[1]/a"
    )

    item[:actors] = loop_to_array(
      "//h4[.='Hrají: ']/following::span[1]/a | " +
      "//h4[.='Hrají: ']/following::span[1]/span[1]/a"
    )

    item[:musicians] = loop_to_array(
      "//h4[.='Hudba: ']/following::span[1]/a | " +
      "//h4[.='Hudba: ']/following::span[1]/span[1]/a"
    )

    item[:producers] = loop_to_array(
      "//h4[.='Produkce: ']/following::span[1]/a | " +
      "//h4[.='Produkce: ']/following::span[1]/span[1]/a"
    )

    save_to "results.json", item, format: :pretty_json
  end

  def loop_to_array(xpath)
    items = []

    @response.xpath(xpath).each do |item|
      items << item.text
    end

    items
  end
end

CsfdSpider.crawl!
