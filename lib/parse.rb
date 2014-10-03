module Parse
  require 'open-uri'
  require 'nokogiri'

  def self.parse(url)
    doc = Nokogiri::HTML(open(url).read)
    abilities = doc.search('a[@href^="/garrisonabilities"]')
    abilities.each do |ability|
      ability_name = ability.text.to_s
    end
    blah = true
  end
end