class Flag < ActiveRecord::Base
  has_and_belongs_to_many :missions, -> { uniq }

  validates :name,
            presence: true,
            uniqueness: true
end
