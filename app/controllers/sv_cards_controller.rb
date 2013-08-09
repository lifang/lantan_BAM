#encoding: utf-8
class SvCardsController < ApplicationController
  require 'will_paginate/array'
  layout "sale"
  before_filter :get_store

  def index
    @sv_cards = SvCard.where(["store_id = ? ", params[:store_id].to_i]).where(["status = ?", SvCard::STATUS[:NORMAL]]).order("created_at desc")
    .paginate(:page => params[:page] ||= 1, :per_page => SvCard::PER_PAGE)
  end

  def new
    @card = @store.sv_cards.new
    respond_to do |format|
      format.js
    end
  end

  def create
    if SvCard.where(["types = ? and name = ? and status = ? and store_id = ?",
                  params[:sv_card][:types], params[:sv_card][:name], SvCard::STATUS[:NORMAL], @store.id]).blank?
      img_obj = params[:sv_card][:img_url]
      params[:sv_card].delete_if{|key, value| key=="img_url"}
      if params[:sv_card][:types].to_i == SvCard::FAVOR[:DISCOUNT] #打折卡
        sv_card = SvCard.new(params[:sv_card].merge({:status => SvCard::STATUS[:NORMAL], :store_id => @store.id}))
        if sv_card.save
          begin
            url = SvCard.upload_img(img_obj, sv_card.id, Constant::SVCARD_PICS, params[:sv_card][:store_id], Constant::SVCARD_PICSIZE)
            sv_card.update_attribute("img_url", url)
          rescue
            flash[:notice] = "图片上传失败!"
          end
        end
      else
        sv_card = SvCard.new(params[:sv_card].merge({:status => SvCard::STATUS[:NORMAL], :price => params[:started_money], :store_id => @store.id}))
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
      redirect_to store_sv_cards_path(@store)
    else
      flash[:notice] = "创建失败，已有同名的优惠卡存在!"
      redirect_to request.referer
    end
    
  end

  def show
    @sv_card = SvCard.find_by_id(params[:id])
    @spr = @sv_card.svcard_prod_relations[0]
    respond_to do |format|
      format.js
    end
  end

  def destroy
    sc = SvCard.find_by_id(params[:id].to_i)
    if sc.nil?
      flash[:notice] = "删除失败!"
    else
      if sc.update_attribute("status", SvCard::STATUS[:DELETED])
        flash[:notice] = "删除成功!"
      else
        flash[:notice] = "删除失败!"
      end
    end
       redirect_to store_sv_cards_path(@store)
  end

  def update
    sv_card = SvCard.find_by_id(params[:id].to_i)
    if SvCard.where(["id != ? and types= ? and name = ? and status = ? and store_id = ?", sv_card.id, sv_card.types,
                    params[:sv_card][:name], SvCard::STATUS[:NORMAL], sv_card.store_id]).blank?
      img_obj = params[:sv_card][:img_url]
      params[:sv_card].delete_if{|key, value| key=="img_url"}
      if sv_card.update_attributes(params[:sv_card])
        if sv_card.types == SvCard::FAVOR[:SAVE]
          sv_card.update_attribute("price", params[:started_money])
          SvcardProdRelation.destroy_all("sv_card_id = #{sv_card.id}")
          SvcardProdRelation.create(:sv_card_id => sv_card.id, :base_price => params[:started_money].to_f, :more_price => params[:ended_money].to_f)
        end
        if !img_obj.nil?
          begin
            url = SvCard.upload_img(img_obj, sv_card.id, Constant::SVCARD_PICS, @store.id, Constant::SVCARD_PICSIZE)
            sv_card.update_attribute("img_url", url)
          rescue
            flash[:notice] = "图片上传失败!"
          end
        end
        flash[:notice] = "更新成功!"
      end
    else
      flash[:notice] = "更新失败，已有同名的优惠卡存在!"
    end
    redirect_to request.referer
  end

  def sell_situation  #销售情况
    @card_type = params[:card_type].nil? ? 2 : params[:card_type].to_i
    @started_time = params[:started_time]
    @ended_time = params[:ended_time]
    @store_id = params[:store_id].to_i
    sql = "select csr.*, c.name name, c.mobilephone phone, sc.types type
           from c_svc_relations csr right join sv_cards sc on csr.sv_card_id = sc.id
           right join customers c on csr.customer_id = c.id where sc.store_id = #{@store_id}
            and csr.status = #{CSvcRelation::STATUS[:valid]}"
    unless @started_time.nil? || @started_time.strip == ""
      sql += " and date_format(csr.created_at,'%Y-%m-%d') >= '#{@started_time}'"
    end
    unless @ended_time.nil? || @ended_time.strip == ""
      sql += " and date_format(csr.created_at,'%Y-%m-%d') <= '#{@ended_time}'"
    end
    unless @card_type == 2
      sql += " and sc.types = #{@card_type}"
    end
    sql += " order by csr.created_at desc"
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

  def use_detail
    @started_time = params[:started_time]
    @ended_time = params[:ended_time]
    base_sql = (@started_time.nil? || @started_time.blank?) ? "1=1" : "o.created_at >= '#{@started_time}'"
    base_sql << " and "
    base_sql << ((@ended_time.nil? || @ended_time.blank?) ? "1=1" : "date_format(o.created_at,'%Y-%m-%d') <= '#{@ended_time}'")
    orders = Order.find_by_sql("select o.id id, o.code code,o.price price, c.name name, cn.num num from orders o left join customers c on c.id = o.customer_id
                                 left join car_nums cn on cn.id = o.car_num_id inner join order_pay_types opt on opt.order_id = o.id
                                 where o.store_id = #{@store.id} and (opt.pay_type = #{OrderPayType::PAY_TYPES[:SV_CARD]} || opt.pay_type = #{OrderPayType::PAY_TYPES[:DISCOUNT_CARD]}) and #{base_sql} group by o.id")
    @product_hash = OrderProdRelation.order_products(orders)
    @orders = orders.paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
  end

  def search_left_price
    @customer_name = params[:customer_name]
    @customer_tel = params[:customer_tel]
    base_sql = (@customer_name.nil? || @customer_name.blank?) ? "1=1" : "c.name like '%#{@customer_name.gsub('%', '\%')}%'"
    base_sql << " and "
    base_sql << ((@customer_tel.nil? || @customer_tel.blank?) ? "1=1" : "c.mobilephone like '%#{@customer_tel.gsub('%', '\%')}%'")
    @customers = Customer.find_by_sql("select csr.id csr_id, c.name name, cn.num num, c.mobilephone mobilephone, sc.name s_name, csr.left_price left_price from customers c
                                       inner join c_svc_relations csr on csr.customer_id = c.id left join sv_cards sc on sc.id = csr.sv_card_id
                                       left join customer_num_relations cnr on cnr.customer_id = c.id left join car_nums cn on cn.id = cnr.car_num_id
                                       where c.status = #{Customer::STATUS[:NOMAL]} and #{base_sql} and sc.types = #{SvCard::FAVOR[:SAVE]} and sc.store_id=#{params[:store_id]}").
                                       paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
  end

  def left_price
    @svcard_use_records = SvcardUseRecord.where("c_svc_relation_id = #{params[:c_svc_relation_id]}")
  end

  private
  def get_store
    @store = Store.find_by_id(params[:store_id])
  end
end
