function collect_info(store_id,station_id){
    if (parseInt($("#t_status").val())==0){
        $.ajax({
            async:true,
            type:'post',
            dataType:'json',
            url:"/stores/"+store_id+"/stations/collect_info",
            data:{
                store_id : store_id
            },
            success : function(data) {
                $("#t_status").val(1);
                var types=["day_num","month_num"];
                for(var i=0;i<types.length;i++){
                    var month_num = data[types[i]];
                    for(var item in month_num){
                        $($("#water_"+item+" span")[i+1]).html(month_num[item][0]);
                        $($("#gas_"+item+" span")[i+1]).html(month_num[item][1]);
                        $($("#num_"+item+" span")[i+1]).html(month_num[item][2]);
                    }
                }
                $("#site_"+station_id).css("display","");
            }
        })
    }else{
        //        $("#site_"+station_id).slideToggle("slow");
        $("#site_"+station_id).css("display","");
    }

}

function request_order(order_id){
    $.ajax({
        async:true,
        type:'get',
        dataType:'script',
        url:"/orders/"+order_id+"/order_info"
    })
}

function handle_order(order_id,types){
    if (types == "complete_pay" && !confirm("请确认客户已经付款？")){
        window.location.reload();
        return false;
    }
    $.ajax({
        async:true,
        type:'post',
        dataType:'json',
        url:"/stations/handle_order",
        data :{
            order_id : order_id,
            types : types
        },
        success : function(data){
            $("#related_order_partial h1 a").trigger("click");
            tishi_alert(data.msg);
            setTimeout(function(){
                window.location.reload();
            },1000)
        }
    })
}


