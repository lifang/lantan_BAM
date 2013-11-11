function new_save_card(){   //新建储值卡
    popup("#save_cards_div");
}

function create_save_card_valid(obj){
    var name = $.trim($("#scard_name").val());
    var img = $.trim($("#scard_img").val());
    var s_money = $.trim($("#scard_started_money").val());
    var e_money = $.trim($("#scard_ended_money").val());
    var desc = $.trim($("#scard_desc").val());
    if(name==""){
        tishi_alert("请输入储值卡名称");
    }else if(img==""){
        tishi_alert("请选择储值卡图片!");
    }else if(s_money==""){
        tishi_alert("请输入充值金额!");
    }else if(isNaN(s_money) || parseInt(s_money)<=0){
        tishi_alert("请输入正确的充值金额!");
    }else if(e_money==""){
        tishi_alert("请输入赠送金额!");
    }else if(isNaN(e_money) || parseInt(e_money)<=0){
        tishi_alert("请输入正确的赠送金额!");
    }else if(desc==""){
        tishi_alert("请输入储值卡说明!");
    }else{
        $(obj).parents("form").submit();
    }
}

function edit_save_card(store_id, cid){
    $.ajax({
       type: "get",
       url: "/stores/"+store_id+"/save_cards/"+cid+"/edit",
       dataType: "script"
    })
}

function update_save_card_valid(obj){
    var name = $.trim($("#edit_scard_name").val());
    var s_money = $.trim($("#edit_scard_started_money").val());
    var e_money = $.trim($("#edit_scard_ended_money").val());
    var desc = $.trim($("#edit_scard_desc").val());
    if(name==""){
        tishi_alert("请输入储值卡名称");
    }else if(s_money==""){
        tishi_alert("请输入充值金额!");
    }else if(isNaN(s_money) || parseInt(s_money)<=0){
        tishi_alert("请输入正确的充值金额!");
    }else if(e_money==""){
        tishi_alert("请输入赠送金额!");
    }else if(isNaN(e_money) || parseInt(e_money)<=0){
        tishi_alert("请输入正确的赠送金额!");
    }else if(desc==""){
        tishi_alert("请输入储值卡说明!");
    }else{
        $(obj).parents("form").submit();
    }
}

