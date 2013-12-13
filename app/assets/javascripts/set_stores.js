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

function pay_this_order(store_id,c_id){
    var url = "/stores/"+store_id+"/set_stores/load_order"
    $.ajax({
        type:"post",
        url: url,
        dataType: "script",
        data:{
            customer_id : c_id
        }
    })
}


