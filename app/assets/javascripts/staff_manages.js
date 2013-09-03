function average_cost_detail_summary(store_id){
    var s_time = $("#search_s_time").val();
    var e_time = $("#search_e_time").val();
    var s_type = $("#search_s_type").val();
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/staff_manages/average_cost_detail_summary",
        dataType: "script",
        data: {
            search_s_time : s_time,
            search_e_time : e_time,
            search_s_type : s_type
        }
    })
}