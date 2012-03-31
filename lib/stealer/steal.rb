require 'mechanize'
require 'csv'
require 'nokogiri'
require 'open-uri'

module Stealer
  class Scraper
    
    def initialize *args
      @free_dic = "http://ninjawords.com/"
      @agent = Mechanize.new
      @page = @agent.get @free_dic
    end
    
    def run 
      count = 1000
      Words.find_in_batches(:batch_size => 1000) do |batch|
        puts "batch: " + count.to_s
        batch.each do |word|
          scrape word
          sleep 1
        end
        count += 1000
      end
    end

    def scrape word
      # url = File.join(@free_dic, word.word)
      form = @page.form_with(:name => "q")
      form["value"] = word
      page = form.submit(form.button_with(:name => "submit"))
      begin
        # page = open(url).read
        # found = page.scan /1\.\s/
        if found.length >= 1
          Translation.new(:word_id => word.id, :word => word.word, :html => page).save
          word.status = "found"
          word.save
        else
          Translation.new(:word_id => word.id, :word => word.word, :html => page).save
          word.status = "not_found"
          word.save
        end
      rescue OpenURI::HTTPError
        Translation.new(:word_id => word.id, :word => word.word, :html => page).save
        word.status = "failed"
        word.save
      end
      # html_doc = Nokogiri::HTML(page)
    end

    def load_words
      csv = CSV.open("words.csv", 'w', :col_sep => ",", :quote_char => '"')    
      File.open("/home/sasan/dictionaries/words.txt") do |file|
        counter = 1
        while (line = file.gets)
          # Words.new(:word => line.strip).save
          csv << [counter, line.strip, "","", Time.now.to_s(:db),Time.now.to_s(:db)]
          csv.flush
          counter += 1
        end
      end
    end

    def self.get_load_data_infile options
      load_sql = "LOAD DATA LOCAL INFILE '#{options[:file_name]}' #{options[:handle]} " +
        " INTO TABLE #{options[:table]} " +
        " FIELDS TERMINATED BY '#{options[:delimiter]}' " +
        " ENCLOSED BY '#{options[:enclosed_by]}' " + 
        " LINES TERMINATED BY '#{options[:lines]}' "
      if(options.has_key? :ignore)
        load_sql += "IGNORE #{options[:ignore].to_s} LINES"
      end
      ActiveRecord::Base.connection.execute load_sql
      return load_sql
    end
    
  end
end
