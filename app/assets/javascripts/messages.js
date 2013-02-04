function select_customers() {
    var checkboxes = $("#search_div input:checked");
    var send_html = "";
    for (var i=0; i<checkboxes.length; i++) {
        send_html += "<div id='cus_"+ checkboxes[i].value +"'>"+ $("#label_" + checkboxes[i].value).html()
            + "<a href='javascript:void(0);' onclick='delete_cus("+ checkboxes[i].value +")'>删除</a></div>";
    }
    $("#send_div").html(send_html);
}

function delete_cus(customer_id) {
   $("#c_" + customer_id).removeAttr("checked");
   $("#cus_" + customer_id).remove();   
}

function show_name() {
    $("#content").val($("#content").val() + "%name%");
}

function show_store_name(store_name) {
    $("#content").val($("#content").val() + "--" + store_name);
}