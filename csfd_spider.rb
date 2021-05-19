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
      request_to :parse_repo_page, url: absolute_url(a[:href], base: url)
    end

    # next_page = response.at_xpath("//a[@class='next_page']")
    #
    # if next_page.present?
    #   request_to :parse, url: absolute_url(next_page[:href], base: url)
    # end
  end

  def parse_repo_page(response, url:, data: {})
    @response = response

    item = {}

    item[:title] = @response.xpath("//h1").text.strip
    item[:year] = @response.xpath("//span[@itemprop='dateCreated']").text.strip
    item[:genres] = @response.xpath("//div[@class='genres']").text.split(' / ')
    item[:rating_value] = @response.xpath("//meta[@itemprop='ratingValue']").attribute('content')
    item[:rating_count] = @response.xpath("//meta[@itemprop='ratingCount']").attribute('content')
    item[:review_count] = @response.xpath("//meta[@itemprop='reviewCount']").attribute('content')
    item[:based_on] = @response.xpath("//h4[.='Předloha: ']/following::span[1]/a").text.strip
    item[:directors] = loop_data "//h4[.='Režie: ']/following::span[1]/a"
    item[:scenarists] = loop_data "//h4[.='Scénář: ']/following::span[1]/a"
    item[:actors] = loop_data "//h4[.='Hrají: ']/following::span[1]/a | //h4[.='Hrají: ']/following::span[1]/span[1]/a"
    item[:musicians] = loop_data "//h4[.='Hudba: ']/following::span[1]/a"
    item[:producers] = loop_data "//h4[.='Produkce: ']/following::span[1]/a"

    # item[:repo_name] = response.xpath("//h1/strong[@itemprop='name']/a").text
    # item[:repo_url] = url
    # item[:description] = response.xpath("//span[@itemprop='about']").text.squish
    # item[:tags] = response.xpath("//div[@id='topics-list-container']/div/a").map { |a| a.text.squish }
    # item[:watch_count] = response.xpath("//ul[@class='pagehead-actions']/li[contains(., 'Watch')]/a[2]").text.squish
    # item[:star_count] = response.xpath("//ul[@class='pagehead-actions']/li[contains(., 'Star')]/a[2]").text.squish
    # item[:fork_count] = response.xpath("//ul[@class='pagehead-actions']/li[contains(., 'Fork')]/a[2]").text.squish
    # item[:last_commit] = response.xpath("//span[@itemprop='dateModified']/*").text

    save_to "results.json", item, format: :pretty_json
  end

  def loop_data(xpath)
    items = []

    @response.xpath(xpath).each do |item|
      items << item.text
    end

    items
  end
end

CsfdSpider.crawl!
