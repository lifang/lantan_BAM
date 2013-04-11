#encoding: utf-8
class PackageCardsController < ApplicationController
  before_filter :sign?
  # 营销管理 -- 套餐卡
  layout 'sale'
  require 'will_paginate/array'

  def index
    @cards=PackageCard.paginate_by_sql("select name,img_url,started_at,ended_at,id from package_cards where store_id=#{params[:store_id]}
         and status =#{PackageCard::STAT[:NORMAL]}", :page => params[:page], :per_page => Constant::PER_PAGE)
    @prods ={}
    @cards.each do |card|
      @prods[card.id]=Product.find_by_sql("select s.name,p.product_num num from products s inner join
     pcard_prod_relations p on s.id=p.product_id  where p.package_card_id=#{card.id}")
    end
  end #套餐卡列表
  
  def create
    parms = {:name=>params[:name],:img_url=>params[:img_url],:started_at=>params[:started_at],:ended_at=>params[:ended_at],
      :store_id=>params[:store_id],:status=>PackageCard::STAT[:NORMAL],:price=>params[:price],:created_at=>Time.now.strftime("%Y-%M-%d")
    }
    pcard =PackageCard.create(parms)
    begin
      pcard.update_attributes(:img_url=>Sale.upload_img(params[:img_url],pcard.id,Constant::PCARD_PICS,pcard.store_id,Constant::C_PICSIZE))  if params[:img_url]

      params[:sale_prod].each do |key,value|
        PcardProdRelation.create(:package_card_id=>pcard.id,:product_id=>key,:product_num=>value)
      end
    rescue
      flash[:notice] ="图片上传失败，请重新添加！"
    end
    redirect_to "/stores/#{params[:store_id]}/package_cards"
  end #添加套餐卡


  def sale_records
    p_cards =PackageCard.search_pcard(params[:store_id])
    @cards= p_cards.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    @card_fee = p_cards.inject(0) {|num,card| num+card.price }
    @pcards = p_cards.inject(Array.new) {|p_hash,card| p_hash << [card.id,card.p_name];p_hash.uniq }
    p @pcards
    #content中存放使用情况 将所有产品或服务以字符串组合存放，包含 产品id,name,剩余次数
  end #销售记录

  #加载产品或者服务类型
  def pcard_types
    sql = "select id,name from products where  store_id=#{params[:store_id]} and status=#{Product::IS_VALIDATE[:YES]}"
    sql += " and types=#{params[:sale_types]}" if params[:sale_types] != "" || params[:sale_types].length !=0
    sql += " and name like '%#{params[:sale_name]}%'" if params[:sale_name] != "" || params[:sale_name].length !=0
    @products=Product.find_by_sql(sql)
  end

  #添加套餐卡
  def add_pcard
    @pcard=PackageCard.new
  end

  #编辑套餐卡
  def edit_pcard
    @pcard=PackageCard.find(params[:id])
    @sale_prods=Product.find_by_sql("select s.name,p.product_num num,s.id from products s inner join
     pcard_prod_relations p on s.id=p.product_id  where p.package_card_id=#{params[:id]}")
  end

  #更新套餐卡
  def update_pcard
    pcard=PackageCard.find(params[:id])
    parms = {:name=>params[:name],:img_url=>params[:img_url],:started_at=>params[:started_at],
      :ended_at=>params[:ended_at],:price=>params[:price]
    }
    parms.merge!(:img_url=>Sale.upload_img(params[:img_url],pcard.id,Constant::PCARD_PICS,pcard.store_id,Constant::C_PICSIZE))  if params[:img_url]
    pcard.update_attributes(parms)
    pcard.pcard_prod_relations.inject(Array.new) {|arr,sale_prod| sale_prod.destroy}
    params[:sale_prod].each do |key,value|
      PcardProdRelation.create(:package_card_id=>pcard.id,:product_id=>key,:product_num=>value)
    end
    redirect_to "/stores/#{params[:store_id]}/package_cards"
  end

  #删除活动
  def delete_pcard
    PackageCard.find(params[:id]).update_attributes(:status=>PackageCard::STAT[:INVALID])
    respond_to do |format|
      format.json {
        render :json=>{:message=>"删除成功"}
      }
    end
  end

  def search
    session[:pcard],session[:car_num],session[:c_name],session[:created_at],session[:ended_at]=nil,nil,nil,nil,nil
    session[:pcard],session[:car_num],session[:c_name]=params[:pcard],params[:car_num],params[:c_name]
    session[:created_at],session[:ended_at]=params[:created_at],params[:ended_at]
    redirect_to "/stores/#{params[:store_id]}/package_cards/search_list"
  end

  def search_list
    p_cards=PackageCard.search_pcard(params[:store_id],session[:pcard],session[:car_num],session[:c_name],session[:created_at],session[:ended_at])
    @cards=p_cards.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    @card_fee = p_cards.inject(0) {|num,card| num+card.price }
    @pcards = p_cards.inject(Array.new) {|p_hash,card| p_hash << [card.id,card.name]}
    render "sale_records"
  end
  
end
