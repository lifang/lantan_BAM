#encoding: utf-8
class MessageRecord < ActiveRecord::Base
  has_many :send_messages
  belongs_to :store

  STATUS = {:NORMAL => 0, :SENDED => 1,:IGNORE => 2} # 0 未发送 1 已发送 2 已忽略

  def self.send_code order_id,phone
    order = Order.find_by_id order_id
    status = 0
    if order && order.customer.mobilephone == phone
      self.create(:content => "订单：#{order.code},储值卡支付的验证码为：123456", :store_id => order.store_id, :status => STATUS[:NORMAL])
      status = 1
    end
    status
  end
end
