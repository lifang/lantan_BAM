#encoding: utf-8
class Api::ChangeController < ApplicationController
  def change_pwd
    sv_card = CSvRelation.where(:customer_id=>params[:customer_id],:sv_card_id=>params[:sv_card_id],:status=>CSvcRelation::STATUS[:valid])
    if sv_card
      if params[:verify_code] == sv_card.verify_code
        n_password = params[:n_password]
        if sv_card.update_attribute(:password, MD5::digest(n_password))
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
end
