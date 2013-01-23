class MessageRecord < ActiveRecord::Base
  attr_accessible :content, :send_at, :status
end
