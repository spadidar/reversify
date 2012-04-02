require 'mechanize'
require 'csv'
require 'nokogiri'
require 'open-uri'

module Stealer
  class Scraper
    
    def initialize *args
      @free_dic = "http://www.dict.org/bin/Dict"
      @agent = Mechanize.new
      @page = @agent.get @free_dic
    end
    
    def run 
      count = 1000
      Words.find_in_batches(:batch_size => 1000, :conditions => ["id > 13099"]) do |batch|
        puts "batch: " + count.to_s
        batch.each do |word|
          scrape word
          sleep 0.5
        end
        count += 1000
      end
    end

    def scrape word
      form = @page.form_with :name => "DICT"
      form.field_with(:name => "Query").value = word.word
      page = form.submit
      begin
        found = page.body.scan /1\.\s/
        page = page.body
        if found.length >= 1
          Translation.new(:word_id => word.id, :word => word.word, :html => page).save
          word.status = "found"
          word.save
        else
          Translation.new(:word_id => word.id, :word => word.word, :html => page).save
          word.status = "not_found"
          word.save
        end
      rescue Exception => e
        # Translation.new(:word_id => word.id, :word => word.word, :html => page).save
        File.open("/home/sasan/external/words/" + word.word, 'w') {|f| f.write(page) }
        word.status = "exception"
        word.code = e.message.to_s + "\n\n" + e.backtrace.to_s
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
