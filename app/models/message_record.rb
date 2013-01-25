#encoding: utf-8
class MessageRecord < ActiveRecord::Base
  has_many :send_messages
end
