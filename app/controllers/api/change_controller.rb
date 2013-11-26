#encoding: utf-8
class Api::ChangeController < ApplicationController
  def change_pwd
    sv_card = CSvRelation.where(:customer_id=>params[:customer_id],:sv_card_id=>params[:sv_card_id],:status=>CSvcRelation::STATUS[:valid])
    if sv_card && params[:verify_code] == sv_card.verify_code
      verify_code = params[:verify_code]
      n_password = params[:n_password]
    end
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
