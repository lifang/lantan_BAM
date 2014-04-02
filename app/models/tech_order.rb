class TechOrder < ActiveRecord::Base
  belongs_to :staff
  belongs_to :order
end
