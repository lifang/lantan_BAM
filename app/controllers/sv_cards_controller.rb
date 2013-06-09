class SvCardsController < ApplicationController
  require 'will_paginate/array'
  layout "sale"
  def index
    @sv_cards = SvCard.where(["store_id = ?", params[:store_id].to_i]).order("created_at desc")
    .paginate(:page => params[:page] ||= 1, :per_page => SvCard::PER_PAGE)
  end

  def new
    @store = Store.find_by_id(params[:store_id].to_i)
    @card = @store.sv_cards.new
    respond_to do |format|
      format.js
    end
  end

  def create
    current_store = Store.find_by_id params[:sv_card][:store_id]
    img_obj = params[:sv_card][:img_url]
    params[:sv_card].delete_if{|key, value| key=="img_url"}
    if params[:sv_card][:types].to_i == 0
      sv_card = SvCard.new(params[:sv_card])
      if sv_card.save  #打折卡
         begin
          url = SvCard.upload_img(img_obj, sv_card.id, Constant::SVCARD_PICS, params[:sv_card][:store_id], Constant::SVCARD_PICSIZE)
          sv_card.update_attribute("img_url", url)          
        rescue
          flash[:notice] = "图片上传失败!"
        end
      end
    else
      sv_card = SvCard.new(params[:sv_card])
      if sv_card.save
        SvcardProdRelation.create(:sv_card_id => sv_card.id, :base_price => params[:started_money].to_f, :more_price => params[:ended_money].to_f)
        begin
          url = SvCard.upload_img(img_obj, sv_card.id, Constant::SVCARD_PICS, params[:sv_card][:store_id], Constant::SVCARD_PICSIZE)
          sv_card.update_attribute("img_url", url)
        rescue
          flash[:notice] = "图片上传失败!"
        end
      end
    end
    flash[:notice] = "创建成功!"
    redirect_to store_sv_cards_path(current_store)
  end
  def show
    @sv_card = SvCard.find_by_id(params[:id])
    @store = Store.find_by_id(params[:store_id])
    @spr = @sv_card.svcard_prod_relations[0]
    respond_to do |format|
      format.js
    end
  end

  def update
    sv_card = SvCard.find_by_id(params[:id].to_i)
    current_store = Store.find_by_id(params[:store_id])
    img_obj = params[:sv_card][:img_url]
    params[:sv_card].delete_if{|key, value| key=="img_url"}
    if sv_card.update_attributes(params[:sv_card])
      if sv_card.types == SvCard::FAVOR[:SAVE]
        SvcardProdRelation.destroy_all("sv_card_id = #{sv_card.id}")
        SvcardProdRelation.create(:sv_card_id => sv_card.id, :base_price => params[:started_money].to_f, :more_price => params[:ended_money].to_f)
      end
      if !img_obj.nil?
        begin
          url = SvCard.upload_img(img_obj, sv_card.id, Constant::SVCARD_PICS, current_store.id, Constant::SVCARD_PICSIZE)
          sv_card.update_attribute("img_url", url)
        rescue
          flash[:notice] = "图片上传失败!"
        end
      end
      flash[:notice] = "更新成功!"
      redirect_to store_sv_cards_path(current_store)
    end
  end

  def sell_situation  #销售情况
    @card_type = params[:card_type].nil? ? 2 : params[:card_type].to_i
    @started_time = params[:started_time]
    @ended_time = params[:ended_time]
    @store_id = params[:store_id].to_i
    sql = "select csr.*, c.name name, c.mobilephone phone, sc.price price, sc.types type
           from c_svc_relations csr right join sv_cards sc on csr.sv_card_id = sc.id
           right join customers c on csr.customer_id = c.id where sc.store_id = #{@store_id}"
    unless @started_time.nil? || @started_time.strip == ""
      sql += " and csr.created_at >= '#{@started_time}'"
    end
    unless @ended_time.nil? || @ended_time.strip == ""
      sql += " and csr.created_at <= '#{@ended_time}'"
    end
    unless @card_type == 2
      sql += " and sc.types = #{@card_type}"
    end
    sell_records = CSvcRelation.find_by_sql(sql)
    @sell_records = sell_records.paginate(:page => params[:page] ||= 1,:per_page => 10)
    @count = sell_records.length
    total_money = 0
    sell_records.each do |sr|
      total_money += sr.total_price.to_f
    end
    @total_money = total_money
  end

  def use_collect   #使用情况汇总
    @started_time = params[:started_time]
    @ended_time = params[:ended_time]
    @store_id = params[:store_id].to_i
    sql = "select sur.* from svcard_use_records sur right join c_svc_relations csr on sur.c_svc_relation_id = csr.id right join
           sv_cards sc on csr.sv_card_id = sc.id where sc.store_id = #{@store_id} and sur.types = #{SvcardUseRecord::TYPES[:OUT]}"
    unless @started_time.nil? || @started_time.strip == ""
      sql += " and date_format(sur.created_at, '%Y-%m-%d') >= '#{@started_time}'"
    end
    unless @ended_time.nil? || @ended_time.strip == ""
      sql += " and date_format(sur.created_at, '%Y-%m-%d') <= '#{@ended_time}'"
    end
    sur = SvcardUseRecord.find_by_sql(sql)
    s = sur.group_by{|e|e.created_at.beginning_of_month }
    form_collect = []
    total_money = 0
    s.each do |key, value|
      value.each do |v|
        total_money += v.use_price
      end
      form_collect << key.to_s+","+total_money.to_s
      total_money = 0
    end
    @form_collect = form_collect.paginate(:page => params[:page] ||= 1,:per_page => 10)
  end

  def make_billing   #开具发票
    c_svc_relation = CSvcRelation.find_by_id(params[:svcard_id].to_i)
    if c_svc_relation.is_billing
      render :json => {:status => 0}
    else
      if c_svc_relation.update_attribute("is_billing", 1)
        render :json => {:status => 1}
      else
        render :json => {:status => 0}
      end
    end
  end
end
