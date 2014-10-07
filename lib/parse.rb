module Parse
  require 'open-uri'
  require 'nokogiri'
  require 'time'

  def self.update_all(url)
    doc = Nokogiri::HTML(open(url).read)
    page_count = page_count(doc)
    # Process all pages
    page_count.times do |page|
      process_page(page_count: page+1)
    end
  end

  def self.parse(url)
    cost_regex = /.createIcon\([\s+\d+\w+\,\"]+\)/
    infobox_regex = /Markup\.printHtml\('[\s+\d+\w+\,\"\\+]+'/
    doc = Nokogiri::HTML(open(url).read)
    page_count = page_count(doc)
    missing = find_missing(doc)
    # Process all pages
    page_count.times do |page|
      process_page(page_count: page+1)
    end
    abilities = abilities(doc)
    cost = cost(doc)
    info = info(doc)

    cost_resource = doc.search('h2[text()="Cost"]')[0].next_sibling.next_sibling.children.search('span[@class=q1] a').text.to_s
    cost_javascript = cost_regex.match(doc.search('h2[text()="Cost"]')[0].next_sibling.next_sibling.next_sibling.next_sibling.text.to_s).to_s
    cost_item = Parse.parse_javascript(cost_javascript, type: :item_id)
    cost_quantity = Parse.parse_javascript(cost_javascript, type: :quantity)

    infobox_javascript = infobox_regex.match(doc.search('table[@class=infobox] tr th[@id^=infobox-quick-facts]').first.parent.next_sibling.next_sibling.search('script').text).to_s
    infobox_data = Parse.string_between_markers(infobox_javascript, "Markup.printHtml('", "'")
    if infobox_data
      infobox_data = infobox_data.encode
    end
    test_data = '\x5Bul\x5D\x5Bli\x5DLevel\x3A\x20100\x5B\x2Fli\x5D\x5Bli\x5DRequired\x20item\x20level\x3A\x20645\x5B\x2Fli\x5D\x5Bli\x5DFollowers\x3A\x203\x5B\x2Fli\x5D\x5Bli\x5DDuration\x3A\x208\x20hrs\x5B\x2Fli\x5D\x5Bli\x5DLocation\x3A\x20Highmaul\x5B\x2Fli\x5D\x5Bli\x5DType\x3A\x20Combat\x5B\x2Fli\x5D\x5Bli\x5DMechanic\x3A\x20\x5Burl\x3D\x2Fgarrisonabilities\x3Ffilter\x3Dcr\x3D2\x3Bcrs\x3D29\x3Bcrv\x3D0\x5DPlains\x5B\x2Furl\x5D\x5B\x2Fli\x5D\x5Bli\x5D\x5Bspan\x20class\x3Dq3\x5DRare\x5B\x2Fspan\x5D\x5B\x2Fli\x5D\x5Bli\x5D\x5Bspan\x20class\x3Dq5\x5DExhausting\x5B\x2Fspan\x5D\x5B\x2Fli\x5D\x5B\x2Ful\x5D'

    if infobox_data.include? '[li]'
      puts 'yep'
    end

    blah = true
  end

  def self.find_missing(doc)
    missing = Array.new
    if doc
      rows = doc.search('section[@class^=primary-content] div[@class^=listing-body] table[@class^="listing listing-missions"] tbody tr')
      if rows
        rows.each do |row|
          name = row.search('td[@class^=col-name] a').first.text
          href = row.search('td[@class^=col-name] a').first.attribute('href').to_s
          id = href[/http\:\/\/#{Settings.subdomain}\.wowdb\.com\/garrison\/missions\/(\d+)/m, 1]
          if id && id.is_i?
            # Process id
            mission = Mission.find_by(id: id.to_i)
            unless mission
              missing << [id, name]
            end
          end
        end
      end
    end
    return missing
  end

  def self.page_count(doc)
    items = doc.search('section[@class^=primary-content] div[@class^=listing-header] ul[@class^=b-pagination-list] li')
    count = 0
    if items
      items.each do |item|
        value = item.child.text.to_s
        if value.is_i? && value.to_i > count
          count = value.to_i
        end
      end
    end
    if count > 0
      return count
    else
      return nil
    end
  end

  def self.process_page(args = {})
    page_count = args[:page_count]
    page_suffix = "?page=#{page_count}" if page_count && page_count > 1
    url = "http://#{Settings.subdomain}.wowdb.com/garrison/missions#{page_suffix}"
    doc = doc = Nokogiri::HTML(open(url).read)

    if doc
      rows = doc.search('section[@class^=primary-content] div[@class^=listing-body] table[@class^="listing listing-missions"] tbody tr')
      if rows
        rows.each do |row|
          href = row.search('td[@class^=col-name] a').first.attribute('href').to_s
          id = href[/http\:\/\/#{Settings.subdomain}\.wowdb\.com\/garrison\/missions\/(\d+)/m, 1]
          if id && id.is_i?
            # Process id
            mission = Mission.find_by(id: id.to_i)
            if mission
              mission.remote_update
            else
              Mission.new(id: id.to_i, should_update: true)
            end
          end
        end
      end
    end
  end

  def self.abilities(doc)
    parent = doc.search("section[@class^=u-typography-format] h3[text()='#{Settings.encounters.header_name}']")
    if parent
      if parent.first && parent.first.next_sibling && parent.first.next_sibling.next_sibling
        data = parent.first.next_sibling.next_sibling.search('li[@class=tip]')
        abilities = Array.new
        data.each do |ability|
          abilities << ability.text.strip
        end
        return abilities if abilities.size > 0
      end
    end
  end

  def self.cost(doc)
    parent = doc.search("section[@class^=u-typography-format] h3[text()='#{Settings.cost.header_name}']")
    if parent
      if parent.first && parent.first.next_sibling && parent.first.next_sibling.next_sibling
        # Found item_name
        if parent.first.next_sibling.next_sibling.text.downcase.include?(Settings.cost.item_name.downcase)
          cost = /\d+/.match(parent.first.next_sibling.next_sibling.next_sibling.text.strip)
          return cost.to_s.to_i if cost
        end
      end
    end
  end

  def self.info(doc)
    regex_data = JSON.parse(File.read('config/quickinfo.json'))
    parent = doc.search("aside[@class^=infobox] h4[text()='#{Settings.info.header_name}']")
    if parent
      if parent.first && parent.first.next_sibling && parent.first.next_sibling.next_sibling
        # Found info box
        list = parent.first.next_sibling.next_sibling.search('li')
        if list
          list.each do |item|
            regex_data.each do |value|
              if value['duration']
                # Create duration regex
                Settings.durations.each_with_index do |duration|
                  match = item.text[/#{value['regex']} #{duration[0]}/m, 1]
                  if match
                    # Calculate time (in seconds)
                    seconds = match.to_f * duration[1]
                    #
                  end
                end
              else
                match = item.text[/#{value['regex']}/m, 1]
                if match
                  blah = true
                end
              end
            end

            blah = true

          end
        end
        if parent.first.next_sibling.next_sibling.text.downcase.include?(Settings.cost.item_name.downcase)
          cost = /\d+/.match(parent.first.next_sibling.next_sibling.next_sibling.text.strip)
          return cost.to_s.to_i if cost
        end
      end
    end
  end

  def self.parse_javascript(script, type: :item_id)
    found_script = Parse.string_between_markers(script, '(', ')')
    array = found_script.split(",").map { |s| s.strip.chomp('"').reverse.chomp('"').reverse }
    if type == :item_id
      return array[0].to_i
    elsif type == :quantity
      return array[2].to_i
    end
  end

  def self.string_between_markers(string, marker1, marker2)
    string[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1]
  end
end