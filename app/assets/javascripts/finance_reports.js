// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

function search_finance(e,store_id){
    $(e).attr("onclick","");
    var time = 3;
    var local_timer=setInterval(function(){
        e.innerHTML="查询("+time+")";
        if (time <=0){
            $(e).attr("onclick","search_finance(this,"+store_id+")");
            window.clearInterval(local_timer);
            e.innerHTML="查询";
        }
        time -= 1;
    },1000)
    var p_type = [];
    var parm = {};
    var first_time = $("#c_first").val();
    var last_time = $("#c_last").val();
    var customer_n =$("#customer_n").val()
    var cate_n = $("#cate_n option:selected").val();
    var pay_type = $("#order_types :checked");
    var url = "/stores/"+store_id+"/finance_reports/"
    for(var i=0;i < pay_type.length;i++){
        p_type.push(pay_type[i].value);
    }
  
    if (p_type.length != 0){
        parm["pay_type"]= p_type.join(",");
    }
    if (cate_n != "" && cate_n.length !=0){
        parm["category_id"] = cate_n;
    }
    if (customer_n != "" && customer_n.length != 0){
        parm["customer_name"] = customer_n;
    }
    if (first_time != "" && first_time.length != 0){
        parm["first_time"] = first_time;
    }else{
        parm["first_time"] = 0;
    }
    if (last_time != "" && last_time.length != 0){
        parm["last_time"] = last_time;
    }else{
        parm["last_time"] = 0;
    }
    $.ajax({
        type:"get",
        url: url,
        dataType: "script",
        data: parm
    })

}
