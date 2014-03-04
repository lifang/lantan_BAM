// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

function show_category(store_id,c_id,c_time,c_types){
    var url = "/stores/"+store_id+"/data_manages/ajax_prod_serv"
    $.ajax({
        type:"post",
        url:url,
        dataType: "script",
        data:{
            category_id : c_id,
            c_types : c_types,
            c_time : c_time
        }
    })
}


function search_data(store_id){
    var url = "/stores/"+store_id+"/data_manages/";
    var date = $("#created").val();
    $.ajax({
        type:"get",
        url:url,
        dataType: "script",
        data:{
            date : date
        }
    })
}
