#encoding: utf-8
class SendMessage < ActiveRecord::Base
  belongs_to :message_record
  belongs_to :customer
end
