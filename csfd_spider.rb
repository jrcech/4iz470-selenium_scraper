require 'kimurai'
require 'i18n'

class CsfdSpider < Kimurai::Base
  @name = 'csfd_spider'
  @engine = :selenium_chrome
  @start_urls = ['https://www.csfd.cz/zebricky/vlastni-vyber/']
  @config = {}

  def parse(response, url:, data: {})
    genres = %w(
      Akční
      Animovaný
      Dobrodružný
      Drama
      Fantasy
      Historický
      Horor
      Hudební
      Katastrofický
      Komedie
      Krimi
      Mysteriózní
      Pohádka
      Rodinný
      Romantický
      Sci-Fi
      Sportovní
      Thriller
      Válečný
      Western
      Životopisný
    )

    # browser.click_button 'Rozumím a přijímám'

    genres.each do |genre|
      browser.find(:xpath, "//div[@id='genres-content']/a").click
      browser.find(:xpath, "//span[.='#{genre}']/preceding::input[1]").click
      browser.click_button 'Zobrazit'
      browser.click_link 'Zobrazit celý žebříček'

      wait_for_ajax

      response = browser.current_response

      response.xpath("//a[@class='film-title-name']").each do |a|
        request_to(
          :parse_movie_page,
          url: absolute_url(a[:href], base: url),
          data: genre
        )
      end

      browser.visit url
    end
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
      .xpath("//h4[.='Předloha: ']/following::span[1]")
      .text
      .squish
      .split(', ')

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

    save_to(
      "results/#{I18n.transliterate(data).underscore}.json",
      item,
      format: :pretty_json
    )
  end

  def loop_to_array(xpath)
    items = []

    @response.xpath(xpath).each do |item|
      items << item.text
    end

    items
  end

  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop do
        active = @browser.evaluate_script('jQuery.active')
        break if active == 0
      end
    end
  end
end

CsfdSpider.crawl!
