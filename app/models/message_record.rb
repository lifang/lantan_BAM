#encoding: utf-8
class MessageRecord < ActiveRecord::Base
  has_many :send_messages
  belongs_to :store

  STATUS = {:NOMAL => 0, :SENDED => 1} # 0 未发送 1 已发送
end
