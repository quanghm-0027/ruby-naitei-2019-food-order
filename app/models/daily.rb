class Daily < ApplicationRecord
  belongs_to :restaurant
  has_many :daily_foods

  validates :start_time_order, presence: true
  validates :end_time_order, presence: true, date: {after: :start_time_order}

  class << self
    def today
      Daily.last
    end
  end
end
