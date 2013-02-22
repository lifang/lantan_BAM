//添加产品
function add_prod(store_id){
    $.ajax({
        async:true,
        type : 'post',
        dataType : 'script',
        url : "/stores/"+ store_id+"/products/add_prod"
    });
}

//编辑产品
function edit_prod(id,store_id){
    $.ajax({
        async:true,
        type : 'post',
        dataType : 'script',
        url : "/stores/"+store_id+"/products/"+ id+"/edit_prod"
    });
}

//显示产品
function show_prod(id){
    $.ajax({
        async:true,
        type : 'post',
        dataType : 'script',
        url : "/products/"+ id+"/show_prod"
    });
}

//添加或者编辑产品
function add_product(){
    var name=$("#name").val();
    var base=$("#base_price").val();
    var sale=$("#sale_price").val();
    var standard =$("#standard").val();
    if (name=="" || name.length==0){
        alert("请输入产品的名称");
        return false;
    }
    if(base == "" || base.length==0 || isNaN(parseFloat(base))){
        alert("请输入产品的零售价格");
        return false;
    }
    if(sale == "" || sale.length==0 || isNaN(parseFloat(sale))){
        alert("请输入产品的促销价格");
        return false;
    }
    if (standard=="" || standard.length==0){
        alert("请输入产品的规格");
        return false;
    }
    $("#desc").val(serv_editor.html());
    $("#add_prod").submit();
}


//显示服务
function show_service(id){
    $.ajax({
        async:true,
        type : 'post',
        dataType : 'script',
        url : "/products/"+ id+"/show_serv"
    });
}

// 添加服务
function add_service(store_id){
    $.ajax({
        async:true,
        type : 'post',
        dataType : 'script',
        url : "/stores/"+ store_id+"/products/add_serv"
    });
}

//编辑服务
function edit_service(store_id,id){
    $.ajax({
        async:true,
        type : 'post',
        dataType : 'script',
        url : "/stores/"+ store_id+"/products/"+ id+"/edit_serv"
    });
}

//添加或者编辑服务
function edit_serv(){
    var name=$("#name").val();
    var base=$("#base_price").val();
    var sale=$("#sale_price").val();
    var time=$("#cost_time").val();
    if (name=="" || name.length==0){
        alert("请输入服务的名称");
        return false;
    }
    if(base == "" || base.length==0 || isNaN(parseFloat(base))){
        alert("请输入服务的零售价格");
        return false;
    }
    if(sale == "" || sale.length==0 || isNaN(parseFloat(sale))){
        alert("请输入服务的促销价格");
        return false;
    }
    if(time== "" || time.length==0 || isNaN(parseInt(time))){
        alert("请输入服务的施工时间");
        return false;
    }
    $("#desc").val(serv_editor.html());
    $("#edit_serv").submit();
}

//请求加载产品或服务类别
function load_material(store_id){
    var types=$("#sale_types option:checked").val();
    var name=$("#sale_name").val();
    if (types != "" || name != ""){
        $.ajax({
            async:true,
            type : 'post',
            dataType : 'script',
            url : "/stores/"+ store_id+"/products/load_material",
            data : {
                mat_types : types,
                mat_name : name
            }
        });
    }else{
        alert("请选择类型或填写名称！");
    }
}

//向选择框添加产品服务
function add_mat(e,name){
    var child="<div id='"+e.value+"'><em>"+name +"</em><a href='javascript:void(0)' class='addre_a' \n\
    onclick=\"add_one(\'"+e.value +"\')\" id='add_one"+e.value +"'>+</a><span><input name='material["+e.value +"]' \n\
    type='text' class='addre_input' value='1' id='add_p"+e.value +"' /></span><a href='javascript:void(0)' class='addre_a' \n\
    id='delete_one"+e.value+"'>-</a><a href='javascript:void(0)' class='remove_a' \n\
    onclick='$(this).parent().remove();if($(\"#prod_"+ e.value+"\").length!=0){$(\"#prod_"+ e.value+"\")[0].checked=false;}'>删除</a></div></div>";
    if ($(e)[0].checked){
        if ($("#add_products #"+e.value).length==0){
            $(".popup_body_fieldset #add_products").append(child);
        }else{
            var num=parseInt($("#add_products #add_p"+e.value).val())+1;
            $("#add_products #add_p"+e.value).val(num);
            $("#add_products #delete_one"+e.value).attr("onclick","delete_one('"+ e.value+"')");
        }
    }else{
        $("#add_products #"+e.value).remove();
    }
}

function show_mat(){
    var mats=""
    $("#add_products div").each(function(index,div){
        mats += "<li>"+$("#"+div.id+" em").html()+"<span>/"+$("#add_p"+div.id).val()+"</span></li>"
    })
    $(".seeProDiv_rWidth .srw_ul").html(mats);
    $('.mat_tab').css('display','none');
}
