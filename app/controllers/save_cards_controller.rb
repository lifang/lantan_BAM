#encoding: utf-8
class SaveCardsController < ApplicationController   #储值卡
  require 'will_paginate/array'
  layout "sale"
  before_filter :get_store

  def index
    @types = Category.where(["store_id = ? and types = ?", @store.id, Category::TYPES[:service]])
    @sv_cards = SvCard.find_by_sql(["select sc.id sid, sc.name sname, sc.img_url surl, sc.price sprice,
     sc.description sdesc, sc.use_range srange, spr.base_price bprice, spr.more_price mprice, c.name cname
     from sv_cards sc inner join svcard_prod_relations spr on sc.id=spr.sv_card_id inner join categories c
     on spr.category_id=c.id where sc.store_id=? and sc.status=? and sc.types=? order by sc.created_at desc",
        @store.id, SvCard::STATUS[:NORMAL], SvCard::FAVOR[:SAVE]])
    .paginate(:page => params[:page] ||= 1, :per_page => SvCard::PER_PAGE)
  end

  def create
    name = params[:scard_name]
    use_range = params[:scard_userange]
    category_id = params[:scard_category]
    img = params[:scard_img]
    s_money = params[:scard_started_money]
    e_money = params[:scard_ended_money]
    desc = params[:scard_desc]
    s = SvCard.where(["types = ? and name = ? and status = ? and store_id = ?",SvCard::FAVOR[:SAVE], name,
        SvCard::STATUS[:NORMAL], @store.id])
    if s.blank?
      scard = SvCard.new(:name => name, :types => SvCard::FAVOR[:SAVE], :price => s_money, :description => desc,
        :store_id => @store.id, :use_range => use_range, :status => SvCard::STATUS[:NORMAL])
      if scard.save
        SvcardProdRelation.create(:sv_card_id => scard.id, :base_price => s_money, :more_price => e_money,
          :category_id => category_id)
        if img
          begin
            url = SvCard.upload_img(img, scard.id, Constant::SVCARD_PICS, @store.id, Constant::SVCARD_PICSIZE)
            scard.update_attribute("img_url", url)
            flash[:notice] = "新建成功!"
          rescue
            flash[:notice] = "图片上传失败!"
          end
        else
          flash[:notice] = "新建成功!"
        end
        redirect_to store_save_cards_path
      else
        flash[:notice] = "新建失败!"
        redirect_to request.referer
      end
    else
      flash[:notice] = "新建失败，已有同名的储值卡!"
      redirect_to request.referer
    end
  end

  def edit
    @types = Category.where(["store_id = ? and types = ?", @store.id, Category::TYPES[:service]])
    @save_card = SvCard.find_by_sql(["select sc.*, spr.base_price bprice, spr.more_price mprice, c.id cid
      from sv_cards sc inner join svcard_prod_relations spr
      on sc.id=spr.sv_card_id inner join categories c on spr.category_id=c.id where sc.id=?", params[:id].to_i])[0]
  end

  def update
    name = params[:edit_scard_name]
    use_range = params[:edit_scard_userange]
    category_id = params[:edit_scard_category]
    img = params[:edit_scard_img]
    s_money = params[:edit_scard_started_money]
    e_money = params[:edit_scard_ended_money]
    desc = params[:edit_scard_desc]
    id = params[:id]
    s = SvCard.where(["id != ? and types = ? and name = ? and status = ? and store_id = ?", id, SvCard::FAVOR[:SAVE], name,
        SvCard::STATUS[:NORMAL], @store.id])
    if s.blank?
      scard = SvCard.find_by_id(id)
      if scard.update_attributes(:name => name, :price => s_money, :description => desc, :use_range => use_range)
        SvcardProdRelation.delete_all(:sv_card_id => id)
        SvcardProdRelation.create(:sv_card_id => id, :base_price => s_money, :more_price => e_money, :category_id => category_id)
        if img
          begin
            url = SvCard.upload_img(img, scard.id, Constant::SVCARD_PICS, @store.id, Constant::SVCARD_PICSIZE)
            scard.update_attribute("img_url", url)
            flash[:notice] = "编辑成功!"
          rescue
            flash[:notice] = "图片上传失败!"
          end
        else
          flash[:notice] = "编辑成功!"
        end
      else
        flash[:notice] = "编辑失败!"
      end
    else
      flash[:notice] = "编辑失败，已存在同名的"
    end
    redirect_to request.referer
  end

  def destroy
    scard = SvCard.find_by_id(params[:id].to_i)
    if scard.update_attribute("status", SvCard::STATUS[:DELETED])
      flash[:notice] = "删除成功!"
      redirect_to store_save_cards_path
    else
      flash[:notice] = "删除失败!"
      redirect_to request.referer
    end
  end

  def del_all_scards    #批量删除储值卡
    a = params[:ids]
    SvCard.where(:id=>a).update_all(:status => SvCard::STATUS[:DELETED])
    render :json => 0
  end
  private
  def get_store
    @store = Store.find_by_id(params[:store_id])
  end
end