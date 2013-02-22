function check_customer() {
    if ($.trim($("#name").val()) == "") {
        alert("请输入客户姓名");
        return false;
    }
    if ($.trim($("#mobilephone").val()) == "") {
        alert("请输入客户手机号码");
        return false;
    }
    return true;
}

function customer_mark(customer_id) {
    $("#mark_div").show();
    $("#c_customer_id").val(customer_id);
}

function single_send_message(customer_id) {
    $("#message_div").show();
    $("#m_customer_id").val(customer_id);
}

function check_single_send() {
    if ($.trim($("#content").val()) == "") {
        alert("请您填写需要发送的内容。");
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


function choose_brand() {
    if ($.trim($("#capital_div").val()) != "") {
        alert($.trim($("#capital_div").val()));
        $.ajax({
            async:true,
            dataType:'json',
            data:{
                capital_id : $("#capital_div").val()
            },
            url:"/customers/get_car_brands",
            type:'post',
            success : function(data) {
                alert(data);
                if (data != null && data != undefined) {
                    for (var i=0; i<data.length; i++) {
                        
                    }
                }
            }
        })
    }
    
}