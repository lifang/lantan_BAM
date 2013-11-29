#encoding: utf-8
class Api::ChangeController < ApplicationController
  def change_pwd
    sv_card = CSvcRelation.where(:customer_id=>params[:customer_id],:sv_card_id=>params[:sv_card_id],:status=>CSvcRelation::STATUS[:valid])[0]
    if sv_card
      if params[:verify_code] == sv_card.verify_code
        n_password = params[:n_password]
        if sv_card.update_attribute(:password, Digest::MD5.hexdigest(n_password))
          render :json => {:msg_type => 0, :msg => "密码修改成功!"}
        else
          render :json => {:msg_type => 2, :msg => "修改失败!"}
        end
      else
        render :json => {:msg_type => 1, :msg => "验证码不正确!"}
      end
    else
      render :json => {:msg_type => 2, :msg => "当前卡的余额不足"}
    end
  end

  def send_code
    csvc_relaion = CSvcRelation.where(:customer_id=>params[:customer_id],:sv_card_id=>params[:sv_card_id]).first
    c_phone = csvc_relaion.customer.mobilephone
    if csvc_relaion && c_phone
      begin
        csvc_relaion.update_attribute(:verify_code, proof_code(6).downcase)
        send_message = "#{csvc_relaion.sv_card.name}的余额为#{csvc_relaion.left_price}，本次验证码：#{csvc_relaion.verify_code}。"
        message_route = "/send.do?Account=#{Constant::USERNAME}&Password=#{Constant::PASSWORD}&Mobile=#{c_phone.strip}&Content=#{URI.escape(send_message)}&Exno=0"
        create_get_http(Constant::MESSAGE_URL, message_route)
        msg_type = 0
        msg = "发送成功"
      rescue
        msg_type =1
        msg = "发送失败"
      end
    else
      msg_type =1
      msg = "用户或储值卡不存在"
    end
    render :json=>{:msg_type=>msg_type,:msg=>msg}

  end

  def sv_records
    render :json => SvcardUseRecord.joins(:c_svc_relation=>:sv_card).select("name,content,use_price,svcard_use_records.left_price,
    date_format(svcard_use_records.created_at,'%Y.%m.%d') created_at").where("sv_cards.store_id=#{params[:store_id]} and
   c_svc_relations.customer_id=#{params[:customer_id]}").where(:types=>SvcardUseRecord::TYPES[:OUT]).group_by{|i|i.name}
    #   sv_cards = SvcardUseRecord.joins(:c_svc_relation=>:sv_card).select("sv_cards.name sname,sv_cards.id sid,
    #svcard_use_records.content,svcard_use_records.use_price,svcard_use_records.left_price,date_format(svcard_use_records.created_at,'%Y-%m-%d') created_at#").where("sv_cards.store_id=#{2} and
    #  c_svc_relations.customer_id=#{1}#").where(:types=>SvcardUseRecord::TYPES[:OUT]).group_by{|sc|sc.sid}
    #      svcards_records = []
    #      sv_cards.each do |k, v|
    #        a = {}
    #        b = []
    #        a[:id] = k
    #        a[:name] = v[0].sname
    #        v.each do |obj|
    #          c = {}
    #          c[:content] = obj.content
    #          c[:time] = obj.created_at
    #          c[:u_price] = obj.use_price
    #          c[:l_price] = obj.left_price
    #          b << c
    #        end
    #        a[:records] = b
    #        svcards_records << a
    #      end
    #      render :json => svcards_records
  end

  def use_svcard
    records = CSvcRelation.find_by_sql(["select csr.* from c_svc_relations csr
      left join customers c on c.id = csr.customer_id inner join sv_cards sc on sc.id = csr.sv_card_id
      where sc.types = 1 and csr.password = ? and csr.status = ? and csr.customer_id = ?",
        Digest::MD5.hexdigest(params[:password].strip), CSvcRelation::STATUS[:valid], params[:customer_id].to_i])[0]
    status = 0
    message = ""
    price = params[:price].to_f
    SvcardUseRecord.transaction do
      if !records.blank? 
        status = 0
        message = "余额不足!"
        records.each do |r|
          if r.left_price.to_f >= price
            SvcardUseRecord.create(:c_svc_relation_id => r.id, :types => SvcardUseRecord::TYPES[:OUT],
              :use_price => price, :left_price => r.left_price - price, :content => params[:content].strip)
            r.update_attribute(:left_price, (r.left_price - price))
            status = 1
            message = "支付成功!"
            break
          end
        end
      else
        status = 0
        message = "密码错误!"
      end
      render :json => {:content => message, :status => status}
    end
  end
end
