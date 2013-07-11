function set_store_name(obj){
    var old_name = $(obj).text();
    $(obj).hide();
    $(obj).prev().show();
    $(obj).prev().find("input:first").val(old_name);
    $(obj).prev().find("input:first").focus();
}

function edit_store_name(obj,store_id){
    var new_name = $(obj).val();
    if(new_name == $(obj).parent().next().text()){
        $(obj).parent().hide();
        $(obj).parent().next().show();
    }else{
        $.ajax({
            async:false,
            url: "welcomes/edit_store_name",
            type: "post",
            dataType: "json",
            data: {
                store_id : store_id,
                name : new_name
            },
            success: function(data){
                if(data.status==0){
                    tishi_alert("编辑失败!");
                    $(obj).parent().hide();
                    $(obj).parent().next().show();
                    var old_name = $(obj).parent().next().text();
                    $(obj).val(old_name);
                };
                if(data.status==2){
                    tishi_alert("编辑失败,已有同名的门店!");
                    $(obj).parent().hide();
                    $(obj).parent().next().show();
                    var old_name = $(obj).parent().next().text();
                    $(obj).val(old_name);
                };
                if(data.status==1){
                    tishi_alert("编辑成功!");
                    $(obj).parent().hide();
                    $(obj).parent().next().text(data.new_name);
                    $(obj).parent().next().show();
                }
            }
        })
    }
}