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


