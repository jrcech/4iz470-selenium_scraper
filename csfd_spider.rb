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
    item = {}

    item[:title] = response.xpath("//h1").text.strip
    item[:director] = response.xpath("//span[@itemprop='director']/a").text

    actors = []

    response.xpath("//h4[.='Hrají: ']/following::span[1]/a").each do |actor|
      actors << actor.text
    end

    item[:actors] = actors

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
end

CsfdSpider.crawl!
