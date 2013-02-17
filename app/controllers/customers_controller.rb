#encoding: utf-8
class CustomersController < ApplicationController
  include RemotePaginateHelper
  
  before_filter :customer_tips

  def index
    session[:c_types] = nil
    session[:car_num] = nil
    session[:started_at] = nil
    session[:ended_at] = nil
    session[:name] = nil
    session[:phone] = nil
    session[:is_vip] = nil
    @store = Store.find(params[:store_id].to_i)
    @customers = Customer.search_customer(params[:c_types], params[:car_num], params[:started_at], params[:ended_at],
      params[:name], params[:phone], params[:is_vip], params[:page])
  end

  def search
    session[:c_types] = params[:c_types]
    session[:car_num] = params[:car_num]
    session[:started_at] = params[:started_at]
    session[:ended_at] = params[:ended_at]
    session[:name] = params[:name]
    session[:phone] = params[:phone]
    session[:is_vip] = params[:is_vip]
    redirect_to "/stores/#{params[:store_id]}/customers/search_list"
  end

  def search_list
    @store = Store.find(params[:store_id].to_i)
    @customers = Customer.search_customer(session[:c_types], session[:car_num], session[:started_at], session[:ended_at],
      session[:name], session[:phone], session[:is_vip], params[:page])
    render "index"
  end

  def destroy
    @customer = Customer.find(params[:id].to_i)
    @customer.update_attributes(:status => Customer::STATUS[:DELETED])
    redirect_to request.referer
  end

  def new
    @store = Store.find(params[:store_id].to_i)
  end

  def create
    if params[:name] and params[:mobilephone]
      Customer.create(:name => params[:name].strip, :mobilephone => params[:mobilephone].strip, 
        :other_way => params[:other_way].strip, :sex => params[:sex], :birthday => params[:birthday],
        :address => params[:address], :status => Customer::STATUS[:NOMAL], 
        :types => Customer::TYPES[:NORMAL], :is_vip => Customer::IS_VIP[:NORMAL])
    end
    redirect_to "/stores/#{params[:store_id]}/customers"
  end

  def edit
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
  end

  def update
    if params[:name] and params[:mobilephone]
      customer = Customer.find(params[:id].to_i)
      customer.update_attributes(:name => params[:name].strip, :mobilephone => params[:mobilephone].strip,
        :other_way => params[:other_way].strip, :sex => params[:sex], :birthday => params[:birthday],
        :address => params[:address])
    end
    redirect_to "/stores/#{params[:store_id]}/customers"
  end

  def customer_mark
    customer = Customer.find(params[:c_customer_id].to_i)
    customer.update_attributes(:mark => params[:mark].strip)
    flash[:notice] = "备注成功。"
    redirect_to "/stores/#{params[:store_id]}/customers"
  end

  def single_send_message
    unless params[:content].strip.empty? or params[:m_customer_id].nil?
      MessageRecord.transaction do
        message_record = MessageRecord.create(:store_id => params[:store_id].to_i, :content => params[:content].strip,
          :status => MessageRecord::STATUS[:NOMAL], :send_at => Time.now)
        customer = Customer.find(params[:m_customer_id].to_i)
        SendMessage.create(:message_record_id => message_record.id, :customer_id => customer.id,
          :content => params[:content].strip.gsub("%name%", customer.name), :phone => customer.mobilephone,
          :send_at => Time.now, :status => MessageRecord::STATUS[:NOMAL])
        flash[:notice] = "短信发送成功。"
      end
    end
    redirect_to "/stores/#{params[:store_id]}/customers"
  end

  def show
    @customer = Customer.find(params[:id].to_i)
    @orders = Order.paginate_by_sql(["select * from orders where status != ? and store_id = ? and customer_id = ?
        order by created_at desc", Order::STATUS[:DELETED], params[:store_id].to_i, @customer.id],
      :per_page => 1, :page => params[:page])
    @order_prods = OrderProdRelation.find_by_sql(["select opr.order_id, opr.pro_num, opr.price, p.name
        from order_prod_relations opr left join products p on p.id = opr.product_id
        where opr.order_id in (?)", @orders])

    @revisits = Revisit.paginate_by_sql(["select r.id r_id, r.created_at, r.types, r.content, r.answer, o.code, o.id o_id
          from revisits r left join revisit_order_relations ror
          on ror.revisit_id = r.id left join orders o on o.id = ror.order_id where o.store_id = ? and r.customer_id = ? ",
        params[:store_id].to_i, @customer.id], :per_page => 1, :page => params[:page])

    @complaints = Complaint.paginate_by_sql(["select c.created_at, c.reason, c.suggstion, c.types, c.status,
          c.staff_id_1, c.staff_id_2, o.code from complaints c left join orders o on o.id = c.order_id
          where c.store_id = ? and c.customer_id = ? ", params[:store_id].to_i, @customer.id],
      :per_page => 1, :page => params[:page])
    
  end

end
