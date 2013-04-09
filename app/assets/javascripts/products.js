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
function show_prod(id,store_id){
    $.ajax({
        async:true,
        type : 'post',
        dataType : 'script',
        url : "/stores/"+ store_id+"/products/"+ id+"/show_prod"
    });
}

//添加或者编辑产品
function add_product(e){
    var name=$("#name").val();
    var base=$("#base_price").val();
    var sale=$("#sale_price").val();
    var standard =$("#standard").val();
    var pic_format =["png","gif","jpg","bmp"];
    if (name=="" || name.length==0){
        tishi_alert("请输入产品的名称");
        return false;
    }
    if(base == "" || base.length==0 || isNaN(parseFloat(base))){
        tishi_alert("请输入产品的零售价格");
        return false;
    }
    if(sale == "" || sale.length==0 || isNaN(parseFloat(sale))){
        tishi_alert("请输入产品的促销价格");
        return false;
    }
    if (standard=="" || standard.length==0){
        tishi_alert("请输入产品的规格");
        return false;
    }
    var img_f  = false
    $(".add_img #img_div input[name$='img_url']").each(function (){
        if (this.value!="" || this.value.length!=0){
            var pic_type =this.value.substring(this.value.lastIndexOf(".")).toLowerCase()
            if (pic_format.indexOf(pic_type.substring(1,pic_type.length))== -1){
                img_f = true
            }else{
                $(this).attr("name","img_url["+this.id+"]");
            }
        }     
    })
    if(img_f){
        tishi_alert("请选择正确格式的图片,正确格式是："+pic_format );
        return false
    }
    $("#desc").val(serv_editor.html());
    $("#add_prod").submit();
    $(e).removeAttr("onclick");
}


//显示服务
function show_service(store_id,id){
    $.ajax({
        async:true,
        type : 'post',
        dataType : 'script',
        url : "/stores/"+ store_id+"/products/"+ id+"/show_serv"
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
function edit_serv(e){
    var name=$("#name").val();
    var base=$("#base_price").val();
    var sale=$("#sale_price").val();
    var time=$("#cost_time").val();
    var deduct =$("#deduct_percent").val();
    var pic_format =["png","gif","jpg","bmp"];
    if (name=="" || name.length==0){
        tishi_alert("请输入服务的名称");
        return false;
    }
    if(base == "" || base.length==0 || isNaN(parseFloat(base))){
        tishi_alert("请输入服务的零售价格");
        return false;
    }
    if(sale == "" || sale.length==0 || isNaN(parseFloat(sale))){
        tishi_alert("请输入服务的促销价格");
        return false;
    }
    if(deduct == "" || deduct.length==0 || isNaN(parseFloat(deduct))){
        tishi_alert("请输入技师提成百分点");
        return false;
    }
    if(time== "" || time.length==0 || isNaN(parseInt(time))){
        tishi_alert("请输入服务的施工时间");
        return false;
    }
    var img_f  = false
    $(".add_img #img_div input[name$='img_url']").each(function (){
        if (this.value!="" || this.value.length!=0){
            var pic_type =this.value.substring(this.value.lastIndexOf(".")).toLowerCase()
            if (pic_format.indexOf(pic_type.substring(1,pic_type.length))== -1){
                img_f = true
            }else{
                $(this).attr("name","img_url["+this.id+"]");
            }
        }
    })
    if(img_f){
        tishi_alert("请选择正确格式的图片,正确格式是："+pic_format );
        return false
    }
    $("#desc").val(serv_editor.html());
    $(e).removeAttr("onclick");
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
        tishi_alert("请选择类型或填写名称！");
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
