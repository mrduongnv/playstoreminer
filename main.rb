require "open-uri"
require "uri"
require "net/http"
require 'rubygems'
require 'nokogiri'
require 'mongo'


DATABASE = 'playstore_' + DateTime.parse(Time.now.to_s).strftime("%Y_%m_%d")

@client = Mongo::Client.new(['192.168.1.17:27017'], :database => DATABASE)

@apps_id = []
#@client["app_state_co.touchapps.makeupgirls.weddingedition"].insert_one({_state: 0})


def get_unfetch_app
  database = @client.database
  database.collection_names.each do |name|
    @apps_id << name[10..-1] if @client[name].find({:_state => 0}).count == 1
  end
  @apps_id << "com.sd.google.helloKittyCafe"
end


def scrape(id)
  #@client["app_state_" + id].find_one_and_replace({:_state => 0}, {:_state => 1}) #remove from queue
  begin
    print "Downloading: " + id
    @link = "https://play.google.com/store/apps/details?id=" + id + "&hl=en"

    @data = URI.parse(@link).read

    #print @data

    page = Nokogiri::HTML(@data)

    record = {}
    app_title_css_path = 'html body.no-focus-outline div#wrapper.wrapper.wrapper-with-footer div#body-content.body-content div.outer-container div.inner-container div.main-content div div.details-wrapper.apps.square-cover.id-track-partial-impression.id-deep-link-item div.details-info div.info-container div.info-box-top h1.document-title div.id-app-title'
    app_images_css_path = 'html body.no-focus-outline div#wrapper.wrapper.wrapper-with-footer div#body-content.body-content div.outer-container div.inner-container div.main-content div div.details-wrapper.apps.square-cover.id-track-partial-impression.id-deep-link-item div.details-section.screenshots div.details-section-contents div.details-section-body.expandable div.thumbnails-wrapper div.thumbnails img.screenshot'
    app_desc_css_path = 'html body.no-focus-outline div#wrapper.wrapper.wrapper-with-footer div#body-content.body-content div.outer-container div.inner-container div.main-content div div.details-wrapper.apps.square-cover.id-track-partial-impression.id-deep-link-item div.details-section.description.simple.contains-text-link.apps-secondary-color div.details-section-contents.show-more-container.apps-description div div.show-more-content.text-body'
    app_suggest_app_css_path = 'html body.no-focus-outline div#wrapper.wrapper.wrapper-with-footer div#body-content.body-content div.outer-container div.inner-container div.secondary-content div.details-wrapper div.details-section.recommendation div.details-section-contents div.rec-cluster div.cards div.card.no-rationale.square-cover.apps.medium-minus div.card-content.id-track-click.id-track-impression div.details a.title'
    app_update_css_path = 'html body.no-focus-outline div#wrapper.wrapper.wrapper-with-footer div#body-content.body-content div.outer-container div.inner-container div.main-content div.details-wrapper.apps-secondary-color div.details-section.metadata div.details-section-contents div.meta-info div.content'
    app_rating_one = 'html body.no-focus-outline div#wrapper.wrapper.wrapper-with-footer div#body-content.body-content div.outer-container div.inner-container div.main-content div.details-wrapper.apps div.details-section.reviews div.details-section-contents div.rating-box div.rating-histogram div.rating-bar-container.one span.bar-number'
    app_rating_two = 'html body.no-focus-outline div#wrapper.wrapper.wrapper-with-footer div#body-content.body-content div.outer-container div.inner-container div.main-content div.details-wrapper.apps div.details-section.reviews div.details-section-contents div.rating-box div.rating-histogram div.rating-bar-container.two span.bar-number'
    app_rating_three = 'html body.no-focus-outline div#wrapper.wrapper.wrapper-with-footer div#body-content.body-content div.outer-container div.inner-container div.main-content div.details-wrapper.apps div.details-section.reviews div.details-section-contents div.rating-box div.rating-histogram div.rating-bar-container.three span.bar-number'
    app_rating_four = 'html body.no-focus-outline div#wrapper.wrapper.wrapper-with-footer div#body-content.body-content div.outer-container div.inner-container div.main-content div.details-wrapper.apps div.details-section.reviews div.details-section-contents div.rating-box div.rating-histogram div.rating-bar-container.four span.bar-number'
    app_rating_five = 'html body.no-focus-outline div#wrapper.wrapper.wrapper-with-footer div#body-content.body-content div.outer-container div.inner-container div.main-content div.details-wrapper.apps div.details-section.reviews div.details-section-contents div.rating-box div.rating-histogram div.rating-bar-container.five span.bar-number'
    app_rating_total = 'html body.no-focus-outline div#wrapper.wrapper.wrapper-with-footer div#body-content.body-content div.outer-container div.inner-container div.main-content div.details-wrapper.apps div.details-section.reviews div.details-section-contents div.rating-box div.score-container div.reviews-stats span.reviews-num'

    page.css(app_title_css_path).each do |el|
      record["title"] = el.text.strip
    end


    record["images"] = []
    page.css(app_images_css_path).each do |el|
      record["images"] << ("https:" + el['src'])
    end

    page.css(app_desc_css_path).each do |el|
      record["desc"] = el.text.strip
    end

    page.css(app_rating_one).each do |el|
      record["one"] = el.text.strip
    end

    page.css(app_rating_two).each do |el|
      record["two"] = el.text.strip
    end

    page.css(app_rating_three).each do |el|
      record["three"] = el.text.strip
    end

    page.css(app_rating_four).each do |el|
      record["four"] = el.text.strip
    end

    page.css(app_rating_five).each do |el|
      record["five"] = el.text.strip
    end

    page.css(app_rating_total).each do |el|
      record["total"] = el.text.strip
    end

    page.css(app_suggest_app_css_path).each do |el|
      #record["desc"] = el.text el['title']
      next_app = el['href'][23..-1]
      #if @client["app_state_" + next_app].find({:_state => 0}).count == 0 && @client["app_state_" + next_app].find({:_state => 1}).count == 0 # Not in queue
      #  @client["app_state_" + next_app].insert_one({_state: 0})#in waiting state
      #  @apps_id << c
      #send
      #puts next_app
    end

    update_info = []
    page.css(app_update_css_path).each do |el|
      #puts el.text
      update_info << el.text.strip
    end
    puts update_info
    record["info"] = update_info
    puts record
    #@client["app_info_" + id].insert_one(record) if id.length < 100
  rescue
    puts id
  end

end


get_unfetch_app()

while !@apps_id.empty?
  scrape(@apps_id.pop)
end
