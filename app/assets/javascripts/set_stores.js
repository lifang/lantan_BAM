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
    var t_num = parseInt(parseFloat(num)*1000);
    return  round((t_num%10 == 0 ? t_num : t_num-5)/1000.0,2);

}
function round(v,e){
    var t=1;
    for(;e>0;t*=10,e--);
    for(;e<0;t/=10,e++);
    return Math.round(v*t)/t;
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
        $("#left_pay").html(due_pay);
        $("#due_over").css("display","none");
        return false;
    }else{
        $("#total_pay").html(limit_float(total));
        $("#left_pay").html(limit_float(due_pay-total));
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
    $("#due_over").attr("onclick","").html("可以付款(3)");
    var url = "/stores/"+store_id+"/set_stores/pay_order"
    var n = 3;
    var local_timer = setInterval(function(){
        n -=1;
        $("#due_over").html("可以付款("+n +")");
        if (n <=0){
            window.clearInterval(local_timer);
            $("#due_over").html("可以付款").attr("onclick","check_post("+store_id+","+c_id+","+n_id+")");
        }
    },1000)
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
        $("#left_pay").html(left_pay-due_pay%10);
        if (due_pay%10 >0){
            $("#clear_value").val(due_pay%10);
        }
    }else{
        $("#due_pay").html(due_pay);
        $("#left_pay").html(left_pay+limit_float($.trim($("#hidden_pay").html()))%10);
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
        $("#left_pay").html(limit_float(hidden_pay-total));
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
        $("#left_pay").html(limit_float(hidden_pay+total));
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
        $("#left_pay").html(limit_float(hidden_pay+still_pay-this_value));
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
    $("#confirm_order").attr("onclick","").html("确定(3)");
    var url = "/stores/"+store_id+"/set_stores/pay_order"
    var n = 3;
    var local_timer = setInterval(function(){
        n -=1;
        $("#confirm_order").html("确定("+n +")");
        if (n <=0){
            window.clearInterval(local_timer);
            $("#confirm_order").html("确定").attr("onclick","confirm_pay_order("+store_id+","+c_id+","+n_id+")");
        }
    },1000)
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