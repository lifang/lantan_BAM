function edit_store_validate(obj){
    var flag = true;
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
