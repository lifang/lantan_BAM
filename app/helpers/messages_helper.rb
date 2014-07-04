#encoding: utf-8
module MessagesHelper


  #根据回访要求发送客户短信，会查询所有的门店信息发送,设置的时间为每天的11:30和8点半左右，每天两次执行
  def revist_message()
    store_ids,customer_ids = [],[],[]
    condition = Time.now.strftime("%H").to_i<12 ? "date_format(send_messages.send_at,'%Y-%m-%d %H') between '#{Time.now.beginning_of_day.strftime("%Y-%m-%d %H")}'
    and '#{Time.now.strftime('%Y-%m-%d')+" 11"}'" : "date_format(send_messages.send_at,'%Y-%m-%d %H') between '#{Time.now.strftime('%Y-%m-%d')+" 12"}' and '#{Time.now.end_of_day.strftime("%Y-%m-%d %H")}'"
    send_messages = SendMessage.joins(:store,:message_record).where(condition+" and auto_send=#{Store::AUTO_SEND[:YES]} and
    message_records.types in (#{MessageRecord::M_TYPES[:AUTO_WARN]},#{MessageRecord::M_TYPES[:AUTO_REVIST]})").group_by{|i|
      store_ids << i.store_id;customer_ids << i.customer_id;i.customer_id}
    unless send_messages.empty?
      begin
        Order.transaction do
          customers = Customer.find(customer_ids).inject({}){|h,c|h[c.id]=c;h}
          stores = Store.find(store_ids).inject({}){|h,s|h[s.id]=s;h}
          send_messages,this_prices,pre_sends,message_records = {},{},{},{}
          send_messages.each { |k,v|
            strs = []
            if customers[k] && stores[v.store_id]
              v.each_with_index {|str,index| strs << "#{index+1}.#{str.content}" }
              content ="#{customers[k[:c_id]].name}\t女士/男士,您好,#{stores[v.store_id].name}的美容小贴士提醒您:\n" + strs.join("\r\n")
              piece = content.length%70==0 ? content.length/70 : content.length/70+1
              message_record = MessageRecord.create({:store_id =>v.store_id, :content =>content,:send_at => Time.now,:types=>MessageRecord::M_TYPES[:AUTO_REVIST],
                  :total_num=>piece,:total_fee=>piece*Constant::MSG_PRICE,:status=>SendMessage::STATUS[:FINISHED]})
              this_prices[v.store_id]= (this_prices[v.store_id].nil? ?  0 : this_prices[v.store_id]) + piece
              send_parm = {:message_record_id=>message_record.id,:status=>SendMessage::STATUS[:FINISHED]}
              send_messages[v.store_id].nil? ? send_messages[v.store_id]= {v.id=>send_parm} : send_messages[v.store_id][v.id]=send_parm
              message = {:content => content.gsub(/([   ])/,"\t"), :msid => "#{customers[k[:c_id]].id}", :mobile =>customers[k[:c_id]].mobilephone}
              pre_sends[v.store_id].nil? ? pre_sends[v.store_id] = [message] : pre_sends[v.store_id] << message
              message_records[v.store_id].nil? ? message_records[v.store_id] = [message_record.id] : message_records[v.store_id] << message_record.id
            end
          }
          pre_sends.each do |k,v|
            store = stores[k]
            if  (store.message_fee-this_prices[k]) > Constant::OWE_PRICE
              message_records.delete(k)
              send_message_request(pre_sends[k],20)
              store.warn_store(this_prices[k]*Constant::MSG_PRICE) #提示门店费用信息
              SendMessage.update(send_messages[k].keys,send_messages[k].values)
            end
          end
          MessageRecord.delete_all(:id=>message_records.values.flatten) #余额不足的则删除已生成的记录  因为没发送
        end
      rescue
      end
    end
  end
end
