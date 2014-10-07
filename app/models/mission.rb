class Mission < ActiveRecord::Base
  has_and_belongs_to_many :abilities, -> { uniq }
  has_and_belongs_to_many :flags, -> { uniq }

  after_initialize :remote_update, if: -> { self.should_update }

  attr_accessor :should_update

  validates :id,
            presence: true,
            uniqueness: true
  validates :cooldown,
            allow_blank: true,
            numericality: true
  validates :cost,
            allow_blank: true,
            numericality: true
  validates :duration,
            numericality: true
  validates :followers,
            numericality: true
  validates :item_level,
            allow_blank: true,
            numericality: true
  # :location
  # :mechanic
  validates :name,
            presence: true
  validates :reward,
            allow_blank: true,
            numericality: true

  def ability_list
    if self.abilities
      self.abilities.map(&:name).join(',')
    end
  end

  def flag_list
    if self.flags
      self.flags.map(&:name).join(',')
    end
  end

  def remote_update
    url = "http://#{Settings.subdomain}.wowdb.com/garrison/missions/#{self.id}"
    doc = Nokogiri::HTML(open(url).read)
    if doc
      # Remove abilities
      self.abilities.destroy_all
      # Remove flags
      self.flags.destroy_all
      update_abilities(doc)
      update_cost(doc)
      update_info(doc)
      update_name(doc)
      update_reward(doc)
      self.save
    end
  end

  def update_abilities(doc)
    parent = doc.search("section[@class^=u-typography-format] h3[text()='#{Settings.encounters.header_name}']")
    if parent
      if parent.first && parent.first.next_sibling && parent.first.next_sibling.next_sibling
        data = parent.first.next_sibling.next_sibling.search('li[@class=tip]')
        data.each do |name|
          ability = Ability.find_or_create_by(name: name.text.strip)
          # Create if necessary
          self.abilities << ability unless self.abilities.include?(ability)
        end
      end
    end
  end

  def update_cost(doc)
    parent = doc.search("section[@class^=u-typography-format] h3[text()='#{Settings.cost.header_name}']")
    if parent
      if parent.first && parent.first.next_sibling && parent.first.next_sibling.next_sibling
        # Found item_name
        if parent.first.next_sibling.next_sibling.text.downcase.include?(Settings.cost.item_name.downcase)
          cost = /\d+/.match(parent.first.next_sibling.next_sibling.next_sibling.text.strip)
          cost = cost.to_s.to_i if cost
          # Update
          if cost && self.cost != cost
            self.cost = cost
          end
        end
      end
    end
  end

  def update_field(field, value)
    case field.to_sym
      when :flag
        flag = Flag.find_or_create_by(name: value.to_s.strip)
        # Create if necessary
        self.flags << flag unless self.flags.include?(flag)
      else
        # Update if changed
        if value && self[field.to_sym] != value
          # String as integer convert
          value = value.to_i if value.class == String && value.is_i?
          # Convert to integer if necessary
          value = value.to_i if value.class.is_a? Fixnum
          self[field.to_sym] = value
        end
    end
  end

  def update_info(doc)
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
                    # Update from field
                    self.update_field(value['field'], seconds)
                  end
                end
              else
                match = item.text[/#{value['regex']}/m, 1]
                if match
                  # Check for mechanic
                  match = item.search('span').text.strip if value['field'].to_sym == :mechanic
                  # Update from field
                  self.update_field(value['field'], match)
                end
              end
            end
          end
        end
      end
    end
  end

  def update_name(doc)
    name = doc.search("header[@class^=heading] h2[@class^=header]").text
    self.name = name if name && self.name != name
  end

  def update_reward(doc)
    parent = doc.search("section[@class^=u-typography-format] h3[text()='#{Settings.reward.header_name}'] ~ *")
    if parent
      href = parent.search('ul li a:contains("'+ Settings.reward.item_name + '")')
      if href && href.first && href.first.next
        reward = /\d+/.match(href.first.next.to_s.strip)
        reward = reward.to_s.to_i if reward
        # Update
        if reward && self.reward != reward
          self.reward = reward
        end
      end
    end
  end

  def url
    "http://#{Settings.subdomain}.wowdb.com/garrison/missions/#{id}"
  end
end
