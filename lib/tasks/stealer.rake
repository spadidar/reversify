require 'stealer'

namespace :steal do

  desc "steal translations"
  task :steal => :environment do
    s = Stealer::Scraper.new
    s.run
  end

end
