class Webhook < ApplicationRecord

    validates :source_name, presence: true
    validates :data, presence: true
end
