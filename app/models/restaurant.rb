class Restaurant < ApplicationRecord
  has_many :foods
  has_many :dailies

  class << self
    private

    def inheritance_column
      nil
    end
  end
end
