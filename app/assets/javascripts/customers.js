function check_customer() {
    if ($.trim($("#new_name").val()) == "") {
        tishi_alert("请输入客户姓名");
        return false;
    }
    if ($.trim($("#mobilephone").val()) == "") {
        tishi_alert("请输入客户手机号码");
        return false;
    }
    if ($("#car_models").val() == "") {
        tishi_alert("请选择汽车品牌型号");
        return false;
    }
    return true;
}

function customer_mark(customer_id) {
    popup("#mark_div");
    $("#c_customer_id").val(customer_id);
    $("#mark").val($("#mark_" + customer_id).html());
}

function single_send_message(customer_id) {
    popup("#message_div");
    $("#m_customer_id").val(customer_id);
}

function check_single_send() {
    if ($.trim($("#content").val()) == "") {
        tishi_alert("请您填写需要发送的内容。");
        return false;
    }
    return true;
}

//弹出层关闭
$(function(){
    $(".message .x").click(function(){
        $(this).parent().hide();
    });
})

function show_complaint() {
    $("#complaint_s").show();
    $("#complaint_h").hide();
}

function hide_complaint() {
    $("#complaint_s").hide();
    $("#complaint_h").show();
}


function choose_brand(capital_div, car_brands, car_models) {
    if ($.trim($(capital_div).val()) != "") {
        $.ajax({
            async:true,
            dataType:'json',
            data:{ capital_id : $(capital_div).val() },
            url:"/customers/get_car_brands",
            type:'post',
            success : function(data) {
                if (data != null && data != undefined) {
                        $(car_brands +" option").remove();
                        $(car_brands).append("<option value=''>--</option>");
                        $(car_models +" option").remove();
                        $(car_models).append("<option value=''>--</option>");
                    for (var i=0; i<data.length; i++) {
                        $(car_brands).append("<option value='"+ data[i].id + "'>"+ data[i].name + "</option>");
                    }
                }
            }
        })
    }   
}

function choose_model(car_brands, car_models) {
    if ($.trim($(car_brands).val()) != "") {
        $.ajax({
            async:true,
            dataType:'json',
            data:{ brand_id : $(car_brands).val() },
            url:"/customers/get_car_models",
            type:'post',
            success : function(data) {
                if (data != null && data != undefined) {
                        $(car_models + " option").remove();
                        $(car_models).append("<option value=''>--</option>");
                    for (var i=0; i<data.length; i++) {
                        $(car_models).append("<option value='"+ data[i].id + "'>"+ data[i].name + "</option>");
                    }
                }
            }
        })
    }
}

function check_car_num() {
    if ($.trim($("#new_car_num").val()) != "") {
        $.ajax({
            async:true,
            dataType:'json',
            data:{ car_num : $("#new_car_num").val() },
            url:"/customers/check_car_num",
            type:'post',
            success : function(data) {
                if (data.is_has == false) {
                    tishi_alert("您输入的车牌号码系统中已经存在，点击‘确定’，当前车牌号将修改到当前客户名下。");
                }                
            }
        })
        return false;
    }
}

function check_e_car_num(c_num_id) {
    if ($.trim($("#car_num_" + c_num_id).val()) != "") {
        $.ajax({
            async:true,
            dataType:'json',
            data:{ car_num : $("#car_num_" + c_num_id).val(),
                car_num_id : c_num_id },
            url:"/customers/check_e_car_num",
            type:'post',
            success : function(data) {
                if (data.is_has == false) {
                    tishi_alert("您输入的车牌号码系统中已经存在，点击‘确定’，当前车牌号将修改到当前客户名下。");
                }
            }
        })
        return false;
    }
}

function customer_revisit(order_id, customer_id) {
    popup("#customer_revisit_div");
    $("#rev_order_id").val(order_id);
    $("#rev_customer_id").val(customer_id);
}

function check_revisit() {
    if ($.trim($("#rev_title").val()) == "") {
        tishi_alert("请输入回访的标题");
        return false;
    }
    if ($("#rev_types").val() == "") {
        tishi_alert("请选择回访类型");
        return false;
    }
    if ($.trim($("#rev_content").val()) == "") {
        tishi_alert("请输入回访内容");
        return false;
    }
    if ($.trim($("#rev_answer").val()) == "") {
        tishi_alert("请输入客户留言");
        return false;
    }
    return true;
}

function check_process() {
    if ($("#prod_type").val() == "") {
        tishi_alert("请选择投诉类型");
        return false;
    }
    if ($.trim($("#pro_remark").val()) == "") {
        tishi_alert("请您填写处理意见");
        return false;
    }
    return true;
}

function edit_car_num(car_num_id) {
    if ($.trim($("#buy_year_" + car_num_id).val()) == "") {
        tishi_alert("请输入汽车购买年份");
        return false;
    }
    if ($.trim($("#car_num_" + car_num_id).val()) == "") {
        tishi_alert("请输入车牌号码");
        return false;
    }
    if ($("#car_models_" + car_num_id).val() == "") {
        tishi_alert("请选择汽车品牌型号");
        return false;
    }
    return true;
}


function is_has_trains(complaint_id, obj) {
    $("#is_trains_" + complaint_id).attr("value", "1");
    if (check_process()) {
      obj.submit();
    }    
}
