class SendMessage < ActiveRecord::Base
  attr_accessible :content, :customer_id, :message_record_id, :phone, :send_at, :status
end
