function edit_store_validate(obj){
    var flag = true;
    if($("#store_city").val()==0){
        tishi_alert("请选择门店所属城市!");
        flag = false;
    }
    if($.trim($("#store_name").val()) == "" || $.trim($("#store_name").val()) == null){
        tishi_alert("请输入门店名称!");
        flag = false;
    };
    if($.trim($("#store_contact").val()) == "" || $.trim($("#store_contact").val()) == null){
        tishi_alert("请输入负责人名称!");
        flag = false;
    };
    if($.trim($("#store_phone").val()) == "" || $.trim($("#store_phone").val()) == null){
        tishi_alert("请输入联系电话号码!");
        flag = false;
    };
    if($.trim($("#store_address").val()) == "" || $.trim($("#store_address").val()) == null){
        tishi_alert("请输入门店地址!");
        flag = false;
    };
    if($.trim($("#store_opened_at").val()) == "" || $.trim($("#store_opened_at").val()) == null){
        tishi_alert("请选择开店时间!");
        flag = false;
    };
    if($.trim($("#store_position_x").val()) == null || $.trim($("#store_position_x").val()) == "" || $.trim($("#store_position_y").val()) == null || $.trim($("#store_position_y").val()) == ""){
        tishi_alert("请输入门店坐标!");
        flag = false;
    };
    if(flag){
        $(obj).parents("form").submit();
        $(obj).removeAttr("onclick");
    }
}

function select_city(province_id,store_id){
    if(province_id==0){
        $("#store_city").html("<option value='0'>------</option>")
    }else{
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/set_stores/select_cities",
            dataType: "script",
            data: {
                p_id : province_id
            }
        })
    }
}

function load_register(store_id){
    $("#cash_refresh").removeAttr("onclick");
    var time = 60;
    var local_timer=setInterval(function(){
        $("#cash_refresh").html("刷新("+time+")");
        if (time <=0){
            $("#cash_refresh").attr("onclick","load_register("+store_id+")");
            window.clearInterval(local_timer);
            $("#cash_refresh").html("刷新")
        }
        time -= 1;
    },1000)
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/set_stores/cash_register",
        dataType: "script"
    })
}

function load_search(store_id){
    var c_time = $("#c_first").val();
    var s_time = $("#c_last").val();
    if (c_time != "" && c_time.length !=0 && s_time != "" && s_time.length !=0){
        if (c_time > s_time){
            tishi_alert("开始时间必须小于结束时间");
            return false;
        }
    }
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/set_stores/complete_pay",
        dataType: "script",
        data:{
            first : c_time,
            last : s_time
        }
    })
}

function show_current(e){
    $("div[id*='page_']").css("display",'none');
    $("#page_"+e.id).css("display",'');
    var em = $(e).parent().find("em");
    var a = "<a id='"+ em[0].id+"' onclick='show_current(this)' href='javascript:void(0)'>"+(parseInt(em[0].id)+1)+"</a>"
    var b_em = "<em id='"+e.id+"' class='current'>"+(parseInt(e.id)+1)+"</em>"
    em.replaceWith(a);
    $(e).replaceWith(b_em);
}

function pay_this_order(store_id,c_id,n_id){
    var url = "/stores/"+store_id+"/set_stores/load_order"
    $.ajax({
        type:"post",
        url: url,
        dataType: "script",
        data:{
            customer_id : c_id,
            car_num_id : n_id
        }
    })
}


function show_hihglight(e){
    $('#'+e.id).find('span').toggleClass('highlight');
}


function check_sum(card_id,e){
    $("#order_"+card_id+",#pwd_"+card_id).attr("disabled",!e.checked);
    if (!e.checked){
        $("#order_"+card_id).val(0);
        check_num();
    }
}

function limit_float(num){
    var t_num = parseInt(parseFloat(num)*100);
    return  round((t_num%10 == 0 ? t_num : t_num-5)/100.0,2);
}


function check_num(){
    var total = 0;
    var due_pay = limit_float($.trim($("#due_pay").html()));
    $("#due_over").css("display","none");
    //    $('div.at_way_b > div').find("input[id*='cash_'],input[id*='change_']").val(0);//当调动其他选项则清零付款方式的输入框，也可以选择重新计算

    $("input[id*='order_']").each(function(){
        var left_price = limit_float($.trim($("#left_"+this.id.split("_")[1]).html()));
        var price = limit_float($.trim(this.value))
        var this_value = 0;
        if (!isNaN($.trim(this.value)) && price > 0){
            if (left_price < price){
                this_value = left_price;
            }else{
                this_value = price;
            }
        }
        this.value = this_value;
        total = limit_float(total+this_value);
    })
    if ( due_pay < total){
        tishi_alert("付款额度超过应付金额额度！");
        $("#total_pay").html(0);
        $("#left_pay,#due_money").html(limit_float(due_pay));
        $("#due_over").css("display","none");
        return false;
    }else{
        $("#total_pay").html(limit_float(total));
        $("#left_pay,#due_money").html(limit_float(due_pay-total));
        if (due_pay == total){
            $("#due_over").css("display","block");
        }
    }
    var pay_type = $("#pay_type li[class='hover']").attr("id");
    calulate_v(pay_type);
    return true;
}

function check_post(store_id,c_id,n_id){
    if (!check_num()){ //判断储值卡的金额是否符合
        return false;
    }
    $("#due_over").attr("onclick","").attr("title","正在处理。。。");
    var url = "/stores/"+store_id+"/set_stores/pay_order"
    var pay_order = set_pay_order();
    if (pay_order[0]){
        tishi_alert("储值卡密码不能为空");
        return false;
    }else{
        $.ajax({
            type:"post",
            url:url,
            dataType: "script",
            data:{
                customer_id : c_id,
                car_num_id : n_id,
                pay_order : pay_order[1]
            }
        })
    }
}

//获取退单，优惠，储值卡和抹零和打印发票的数据
function set_pay_order(){
    var pay_order = {};
    var loss = $("#input_loss").css("display");
    var turn = $("#return_order").css("display");
    if (turn == "block"){
        var return_ids = []
        $(".at_client_con  td input:checkbox").each(function(){
            if(this.checked){
                return_ids.push(this.id.split("_")[1]);
            }
        })
        if (return_ids != []){
            pay_order["return_ids"] = return_ids;
        }
    }
    if (loss == "block"){
        var loss_ids = {}
        $(".at_client_con  td input[id*='in_']").each(function(){
            if (limit_float($.trim(this.value))>0){
                loss_ids[this.id.split("_")[1]]= limit_float($.trim(this.value));
            }
            if (!set_reward(this)){ //判断优惠额度是否符合
                return false;
            }
        })
        if(loss_ids != {}){
            pay_order["loss_ids"] = loss_ids;
        }
    }
    var is_password = false;
    if ($("#sv_card_used input:not(:disabled):text").length>0){
        var text = {};
        $("#sv_card_used input:not(:disabled):text").each(function(){
            var pwd = $.trim($("#pwd_"+this.id.split("_")[1]).val());
            if(pwd == "" || pwd.length ==0){
                is_password = true;
            }else{
                if (limit_float($.trim(this.value)) > 0 ){
                    text[this.id.split("_")[1]] = limit_float($.trim(this.value));
                    pay_order[this.id.split("_")[1]] = pwd;
                }
            }
        })
        if (text != {} ){
            pay_order["text"] = text;
        }
    }
    var clear_value = limit_float($.trim($("#clear_value").val()));
    if (clear_value > 0){
        pay_order["clear_value"] = clear_value;
    }
    pay_order["is_billing"] = $("#is_biling")[0].checked ? 1 : 0
    return [is_password,pay_order]
}


function change_order(store_id){
    var c_n = $("#customer_orders option:selected").first().attr("id").split("_");
    $("#discount").val(0);
    pay_this_order(store_id,c_n[0],c_n[1])
}

function change_pay(e){
    var due_pay = limit_float($.trim($("#hidden_pay").html()));
    var left_pay = limit_float($.trim($("#left_pay").html()));
    if(e.checked){
        $("#due_pay").html(due_pay-due_pay%10);
        $("#left_pay,#due_money").html(limit_float(left_pay-due_pay%10));
        if (due_pay%10 >0){
            $("#clear_value").val(due_pay%10);
        }
    }else{
        $("#due_pay").html(due_pay);
        $("#left_pay,#due_money").html(limit_float(left_pay+limit_float($.trim($("#hidden_pay").html()))%10));
        $("#clear_value").val(0);
    }
    check_num();
}

function show_loss(obj_id){
    $(".at_client_con table td[id*='"+obj_id+"']").css("display",'block');
    if (obj_id == "input" && "block" == $("#return_order").css("display")){
        $(".at_client_con table td[id*='"+obj_id+"']").each(function(){
            if ($(this).attr("class")!='hbg'){
                this.disabled = $(this).find("checkbox").attr("checked");
            }
        })
    }
}

function return_check(e){
    var clear_per = $("#clear_per")[0];
    var hidden_pay = limit_float($.trim($("#hidden_pay").html()));
    var total = limit_float($.trim( $("#loss_"+e.id.split("_")[1]).val()));
    var cards = $("#sv_card_used span[id*='"+e.id.split("_")[1] +"_']").find(":checkbox");
    clear_per.checked = false;
    if (e.checked){
        $(e).parent().siblings().css("background","#ebebe3");
        $("#due_pay").html(limit_float(hidden_pay-total));
        $("#left_pay,#due_money").html(limit_float(hidden_pay-total));
        if (hidden_pay==total){
            clear_per.disabled = true;
        }
        $("#hidden_pay").html(limit_float(hidden_pay-total));
        var  this_value = $("#in_"+e.id.split("_")[1]).val(0).attr("disabled",true);
        set_reward(this_value[0])
        if (cards.length >0){
            var card_check = cards[0];
            var card_id = card_check.id.split("_")[1];
            card_check.checked = false
            card_check.disabled = true
            $("#order_"+card_id+",#pwd_"+card_id).attr("disabled",e.checked);
            check_num();
        }
    }else{
        $(e).parent().siblings().css("background","");
        $("#due_pay").html(limit_float(hidden_pay+total));
        $("#left_pay,#due_money").html(limit_float(hidden_pay+total));
        $("#hidden_pay").html(limit_float(hidden_pay+total));
        $("#in_"+e.id.split("_")[1]).attr("disabled",false);
        if ((hidden_pay+total)>0){
            clear_per.disabled = false;
        }
        if (cards.length >0){
            cards[0].disabled = false;
        }
    }
//    change_pay(clear_per);
}

function set_reward(e){
    var clear_per = $("#clear_per")[0];
    var hidden_pay = limit_float($.trim($("#hidden_pay").html()));
    var still_pay = limit_float($.trim($("#hipay_"+e.id.split("_")[1]).val()));
    var loss = limit_float($.trim($("#loss_"+e.id.split("_")[1]).val()));
    var this_value = 0 ;
    var  price = limit_float($.trim(e.value));
    if (!isNaN(price) && price > 0){
        this_value = price;
    }
    e.value = this_value;
    clear_per.checked = false;
    if (this_value > loss){
        tishi_alert("优惠金额超过本单金额！");
        return false;
    }else{
        $("#hipay_"+e.id.split("_")[1]).val(limit_float(this_value));
        $("#due_pay").html(limit_float(hidden_pay+still_pay-this_value));
        $("#left_pay,#due_money").html(limit_float(hidden_pay+still_pay-this_value));
        $("#hidden_pay").html(limit_float(hidden_pay+still_pay-this_value));
        if ((hidden_pay+still_pay-this_value)<= 10){
            clear_per.disabled = true;
        }else{
            clear_per.disabled = false;
        }
        check_num();
        return true;
    //        change_pay(clear_per);
    }
}

function set_change(pay_type){
    var pay_cash = limit_float($.trim($("#cash_"+pay_type).val()));
    var left_pay = limit_float($.trim($("#left_pay").html()));
    $("#change_"+pay_type).val(0);
    if (isNaN(pay_cash) || pay_cash <0){
        $("#cash_"+pay_type).val(0);
        return false;
    }else{
        $("#cash_"+pay_type).val(pay_cash);
        if(left_pay > pay_cash){
            tishi_alert("实收金额不足！");
            return false;
        }else{
            $("#change_"+pay_type).val(limit_float(pay_cash-left_pay));
            return true;
        }
    }
}

function set_card(pay_type){
    var pay_cash = limit_float($.trim($("#cash_"+pay_type).val()));
    var left_pay = limit_float($.trim($("#left_pay").html()));
    if (isNaN(pay_cash) || pay_cash < 0){
        pay_cash = 0;
    }
    $("#cash_"+pay_type).val(pay_cash);
    if(left_pay > pay_cash){
        tishi_alert("实收金额不足！");
        return false;
    }else{
        return true;
    }
}

function confirm_pay_order(store_id,c_id,n_id){
    var left_pay = limit_float($.trim($("#left_pay").html()));
    var pay_order = set_pay_order();
    if (!check_num()){ //判断储值卡的金额是否符合
        return false;
    }
    if (left_pay == 0 && $("#due_over").css("display")=="block"){
        tishi_alert("快捷支付可用");
        return false;
    }else{
        var pay_type = $("#pay_type li[class='hover']").attr("id");
        var second_parm = "";
        var pay_cash = limit_float($.trim($("#cash_"+pay_type).val()));
        if(parseInt(pay_type) == 0){   //如果使用现金支付
            if (!set_change(pay_type)){
                tishi_alert("实收金额不足！");
                return false;
            }
            second_parm = limit_float($.trim($("#change_"+pay_type).val()));
        }
        if(parseInt(pay_type) == 1){   //如果使用刷卡支付
            set_card(pay_type);
            second_parm = $.trim($("#c_set_"+pay_type).val());
        }
        if(parseInt(pay_type) == 5){
            var pay_cash =$.trim($("#cash_"+pay_type).val());
            if (pay_cash == "" || pay_cash.length ==0 || pay_cash.length <0){
                tishi_alert("请求验证权限！");
                return false;
            }
        }
        if(parseInt(pay_type) == 9){   //如果使用挂账支付
            pay_cash = left_pay;
        }
        if (pay_order[0]){
            tishi_alert("储值卡密码不能为空");
            return false;
        }else{
            var t_data ={
                customer_id : c_id,
                car_num_id : n_id,
                pay_order : pay_order[1],
                pay_type : pay_type,
                pay_cash : pay_cash,
                second_parm : second_parm
            }
            set_confirm(store_id,c_id,n_id,t_data);
        }
    }
}

function set_confirm(store_id,c_id,n_id,t_data){
    $("#confirm_order").attr("onclick","").attr("title","正在处理。。。");
    var url = "/stores/"+store_id+"/set_stores/pay_order";
    $.ajax({
        type:"post",
        url:url,
        dataType: "script",
        data: t_data
    })
}

function single_order_print(store_id){
    var print_nums = $(".di_list_l input[id*='print_']:checkbox:checked");
    if (print_nums.length <= 0){
        tishi_alert("请选择打印订单");
        return false;
    }
    if (print_nums.length >1){
        tishi_alert("订单只能选择一个");
        return false;
    }
    window.open("/stores/"+store_id+"/set_stores/single_print?order_id="+print_nums.val(),'_blank', 'height=520,width=625,left=10,top=100');
}


function calulate_v(pay_type){
    if (parseInt(pay_type) == 0){
        var pay_cash = limit_float($.trim($("#cash_"+pay_type).val()));
        var left_pay = limit_float($.trim($("#left_pay").html()));
        var  v = limit_float(pay_cash>left_pay ? pay_cash-left_pay : 0);
        $("#cash_"+pay_type).val(pay_cash)
        $("#change_"+pay_type).val(v);
    }
}

function edit_id_svcard(store_id,card_id){
    var url = "/stores/"+store_id+"/set_stores/edit_svcard";
    var number = $("#id_card").val();
    var pattern = new RegExp("[0-9]")
    if(number =="" || number.length <4 || !pattern.test(number)){
        $(".tab_alert").css("z-index",121);
        tishi_alert("卡号至少为四位数字");
        return false;
    }else{
        $.ajax({
            type:"post",
            url:url,
            dataType: "json",
            data: {
                card_id : card_id,
                number : number
            },
            success : function(data){
                $("#svc_"+data.card_id).html(data.number);
                $("#edit_card .close").trigger("click");
                tishi_alert("修改成功！");
            }
        })
    }
    
}

function show_edit(store_id,card_id){
    $("#id_card").val($("#svc_"+card_id).html());
    $("#confirm_card").attr("onclick","edit_id_svcard("+store_id+","+card_id+")");
    before_center("#edit_card");
    $("#id_card").focus();
}

function auth_car_num(e,store_id){
    var old_c = $("#old_customer").val();
    if(e.value !="" && e.value.length == 7 && old_c != e.value ){
        $("#submit_item,#submit_spinner").toggle();
        var url = "/stores/"+store_id+"/set_stores/search_info";
        var data ={
            car_num : e.value
        }
        $.ajax({
            type:"post",
            url:url,
            dataType: "script",
            data: data
        })
    }else{
        $("#bill_user_info input").removeAttr("readonly");
    }
}

function search_item(store_id){
    var item_id = $("#search_item .hover")[0].id;
    var item_name = $("#search_item #item_name").val();
    var checked_item = $("#checked_item").val();
    var url = "/stores/"+store_id+"/set_stores/search_item";
    var data ={
        item_id : item_id,
        item_name : item_name,
        checked_item : checked_item.split(",")
    }
    $("#spinner_user,#item_btn").toggle();
    $.ajax({
        type:"post",
        url:url,
        dataType: "script",
        data: data
    })
}


function show_div(e){
    $(".card").css("display","none");
    $("#div_"+e.id).css("display","block");
    $(e).addClass('hover').siblings().removeClass('hover')
}

function add_cart(e){
    var price = $(e).parent().find("#price").html();
    var total_price = $("#total_price").html();
    var storage = $(e).parent().find("#storage").html();
    var name = $(e).parent().find("#name").html()
    put_add(e,e.id,storage,name,total_price,price);
}


function add_num(e){
    var max = $(e).parent().parent().eq(0).attr("class");
    var num = $(e).parent().find("input").val();
    var single_price = $(e).parent().parent().find("#price").html(); //单价
    var total_price = $("#total_price").html();
    if (parseInt(max) > parseInt(num)){
        $(e).parent().find("input").val(parseInt(num)+1);
        $(e).parent().parent().find("#t_price").html(change_dot(single_price*(parseInt(num)+1))); //小计价格
        $("#total_price").html(change_dot(round(total_price,2)+round(single_price,2),2)); //设置总价
        if (parseInt(max) == (parseInt(num)+1)){
            e.title = "最大可购买数量";
        }
    }else{
        e.title = "最大可购买数量";
    }
}

function del_num(e){
    var num = $(e).parent().find("input").val();
    var single_price = $(e).parent().parent().find("#price").html(); //单价
    var total_price = $("#total_price").html();
    if (parseInt(num) > 1 ){
        $(e).parent().find("input").val(parseInt(num)-1);
        $(e).parent().parent().find("#t_price").html(change_dot(single_price*(parseInt(num)-1))); //小计价格
        $("#total_price").html(change_dot(round(total_price,2)-round(single_price,2),2)); //设置总价
        if (parseInt(num)==2){
            e.title = "最小购买数量：1";
        }
    }else{
        e.title = "最小购买数量：1";
    }
}

function add_prod(e){
    var price_storage = e.value;
    var price = price_storage.split("_")[0];
    var storage = price_storage.split("_")[1];
    var total_price = $("#total_price").html();
    var e_id = $(e).parent().parent().attr("id");
    var name = $(e).parent().parent().find("td").eq(0).html();
    put_add(e,e_id,storage,name,total_price,price);
}


function put_add(e,e_id,storage,name,total_price,price){
    if(e.checked){
        var total_item = $("#checked_item").val();
        var  total = total_item.split(",");
        if (total_item == "" || total_item.length ==0){
            $("#checked_item").val(e_id);
            add_item(e_id,storage,name,total_price,price);
        }else{
            var  is_new = true;
            var same_id = e_id;
            var pid = e_id.split("_");
            if ( parseInt(pid[1]) == 4 || parseInt(pid[1]) == 5 || parseInt(pid[1]) == 6){ //当下单为产品，服务和打折卡下单时判断是不是已经存在
                for(var i=0;  i < total.length;i++){
                    var d_t = total[i].split("_");
                    if(pid[2] == d_t[2] && parseInt(d_t[1]) != 3){
                        is_new = false;
                        e_id = total[i];
                    }
                }
            }
            if (is_new){
                total.push(e_id);
                $("#checked_item").val(total.join(','));
                add_item(e_id,storage,name,total_price,price);
            }else{
                $("#"+e_id).find("a").eq(1).trigger("onclick"); //如果产品或者服务重复则只增加数量
                var left_item = [];
                if (parseInt(pid[1]) == 4){ //当后选择打折卡时默认设置使用打折卡下单
                    for(var k=0;k< total.length;k++){
                        if(total[k] != e_id){
                            left_item.push(total[k]);
                        }else{
                            $("#table_item #"+e_id).attr("id",same_id);
                            $("#"+e_id ).attr("checked",false);
                        }
                    }
                    left_item.push(same_id);
                    $("#checked_item").val(left_item.join(","));
                }else{
                    $("#"+same_id ).attr("checked",false);
                    tishi_alert("已从打折卡添加！");
                }
            }
        }
    }else{
        del_item(e_id,total_price);
    }
}
function add_item(e_id,storage,name,total_price,price){
    var types_name = "后台下单";
    if (parseInt(e_id.split("_")[1]) == 3){
        types_name = "后台套餐卡下单";
    }else if(parseInt(e_id.split("_")[1]) == 4){
        types_name = "后台打折卡下单";
    }
    $("#table_item").append("<tr id='"+ e_id +"' class='"+(storage == undefined ? 1 : storage)+"'><td>"+ name +"</td>\n\
       <td id='price'>"+price+"</td><td>\n\<a href='javascript:void(0)' class='addre_a' style='font-size:15px;' onclick='del_num(this)'>-</a>\n\
       <span style='margin:5px;'><input type='text' class='addre_input' value='1' readonly /></span><a href='javascript:void(0)' \n\
       class='addre_a' style='font-size:15px;' onclick='add_num(this)'>+</a></td><td id='t_price'>"+price +"</td><td>"+types_name+"</td>\n\
       <td><a href='javascript:void(0)'>删除</a></td></tr>");
    $("#total_price").html(change_dot(round(total_price,2)+round(price,2),2));
}

function del_item(e_id,total_price){
    var checked_item = $("#checked_item").val().split(",");
    var left_item = [];
    var same_id = e_id.split("_");
    if ( parseInt(same_id[1]) == 4 || parseInt(same_id[1]) == 5 || parseInt(same_id[1]) == 6){
        for(var m=0;  m < checked_item.length;m++){
            var del_t = checked_item[m].split("_");
            if(same_id[2] == del_t[2] && parseInt(del_t[1]) != 3){
                e_id = checked_item[m];
            }
        }
    }
    var e_price = $("#table_item #"+e_id+" #t_price").html();
    $("#total_price").html(change_dot(round(total_price,2)-round(e_price,2),2));
    $("#table_item #"+e_id).remove();
    $("#"+e_id +" :checkbox").attr("checked",false);
    for(var k=0;k<checked_item.length;k++){
        if(checked_item[k] != e_id){
            left_item.push(checked_item[k]);
        }
    }
    $("#checked_item").val(left_item.join(","));
}

function search_card(store_id){
    var e = $("#car_num")[0];
    if (e.value !="" && e.value.length == 7){
        $("#old_customer").val("");
        auth_car_num(e,store_id);
    }
}

function submit_item(store_id){
    var e = $("#car_num")[0];
    var checked_item = $("#checked_item").val();
    if (e.value !="" && e.value.length == 7){
        if (checked_item != "" && checked_item.length > 4){
            if(confirm("确认提交订单?")){
                $("#submit_item,#submit_spinner").toggle();
                var items = checked_item.split(",");
                var sub_items = {};
                var url = "/stores/"+store_id+"/set_stores/submit_item";
                var data ={
                    car_num : e.value
                }
                for(var i=0; i< items.length;i++){
                    sub_items[items[i]] = $("#table_item #"+items[i] +" :text").val();
                }
                data["sub_items"] = sub_items;
                $.ajax({
                    type:"post",
                    url:url,
                    dataType: "script",
                    data: data
                })
            }
        }else{
            tishi_alert("请选择项目！")
        }
        
    }else{
        tishi_alert("车牌号码不正确！")
    }
}