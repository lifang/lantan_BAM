function add_prod(){
    $.ajax({
        async:true,
        type : 'post',
        dataType : 'script',
        url : "/products/add_prod"
    });
}

function edit_prod(id){
    $.ajax({
        async:true,
        type : 'post',
        dataType : 'script',
        url : "/products/"+ id+"/edit_prod"
    });
}

function show_prod(id){
    $.ajax({
        async:true,
        type : 'post',
        dataType : 'script',
        url : "/products/"+ id+"/show_prod"
    });
}

function add_product(){
    $("#add_prod").submit();
}