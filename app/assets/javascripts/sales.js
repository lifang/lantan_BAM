
//发布活动验证
function publish_sale(e){
    var name=$("#sale_title").val();
    var disc=$("#s_disc input[name='discount']:checked").val();
    var time=$("#s_time input[name='disc_time']:checked").val();
    var subsidy =$("#s_sub input[name='subsidy']:checked").val();
    var pic_format=["png",'gif',"jpg","bmp","pcx","tiff","jpeg","tga","eps","hdr","tif"]
    var img=$("#img_url").val();
    if (name=="" || name.length==0){
        tishi_alert("请输入本次活动的标题")
        return false;
    }
    if($("#add_products").children().length == 0){
        tishi_alert("请选择产品或服务");
        return false;
    }
    if (disc == undefined){
        tishi_alert("请选择优惠类型");
        return false;
    }
    if (parseInt(disc)==1 && ($("#disc_"+disc).val().length==0 || isNaN(parseFloat($("#disc_"+disc).val())) )){
        tishi_alert("请填写优惠的金额，且为数字");
        return false;
    }
    if (parseInt(disc)==0 && ($("#disc_"+disc).val().length==0 || isNaN(parseFloat($("#disc_"+disc).val())) || parseFloat($("#disc_"+disc).val())<0 || parseFloat($("#disc_"+disc).val()) > 10 )){
        tishi_alert("请填写打折的折扣,且为数字，折扣额度为0到10之间");
        return false;
    }
    if (time == undefined){
        tishi_alert("请选择时间的类型")
        return false;
    }
    if (parseInt(time)==0 && ($("#started_at").val().length == 0 || $("#ended_at").val().length == 0 || $("#started_at").val() > $("#ended_at").val())){
        tishi_alert("请输入活动开始和结束的时间,且开始日期小于结束日期");
        return false;
    }
    if ($("#disc_car_nums").val() == " " || $("#disc_car_nums").val().length==0 ){
        tishi_alert("请输入参加活动的总车辆数");
        return false;
    }
    if (subsidy == undefined){
        tishi_alert("请选择是否需要总店补贴")
        return false;
    }
    if (img == "" || img.length ==0){
        tishi_alert("or not");
        return false;
    }
//    if ((img != "" || img.length !=0) && pic_format.indexOf(img.split(".")[img.split(".").length-1])== -1){
//        tishi_alert("请选择正确格式的图片！")
//    }
    if (parseInt(subsidy)==1 && $("#sub_content").val().length == 0){
        tishi_alert("请输入补贴金额");
        return false;
    }

    $("#intro").val(editor.html());
    $("#one_sale").submit();
//    $(e).removeAttr("onclick");
}

function input_time(){
    if ($("#is_checked")[0].checked){
        $("#started_at,#ended_at").removeAttr("disabled");
    }else{
        $("#started_at,#ended_at").val("").attr("disabled","");
    }
}

function delete_sale(sale_id){
    if(confirm("确定要删除这项活动吗？")){
        $.ajax({
            async:true,
            type : 'post',
            dataType : 'json',
            url : "/sales/delete_sale",
            data : {
                sale_id : sale_id
            },
            success:function(data){
                tishi_alert(data.message);
                window.location.reload();
            }
        });
    }
}

function public_sale(sale_id){
    if(confirm("确定要发布这项活动吗？")){
        $.ajax({
            async:true,
            type : 'post',
            dataType : 'json',
            url : "/sales/public_sale",
            data : {
                sale_id : sale_id
            },
            success:function(data){
                tishi_alert(data.message);
                window.location.reload();
            }
        });
    }
}

//向活动加载产品或服务类别
function load_types(store_id){
    var types=$("#sale_types option:checked").val();
    var name=$("#sale_name").val();
    if (types != "" || name != ""){
        $.ajax({
            async:true,
            type : 'post',
            dataType : 'script',
            url : "/stores/"+ store_id+"/sales/load_types",
            data : {
                sale_types : types,
                sale_name : name
            }
        });
    }else{
        tishi_alert("请选择类型或填写名称！");
    }
}

//为套餐卡加载产品和服务
function pcard_types(store_id){
    var types=$("#sale_types option:checked").val();
    var name=$("#sale_name").val();
    if (types != "" || name != ""){
        $.ajax({
            async:true,
            type : 'post',
            dataType : 'script',
            url : "/stores/"+ store_id+"/package_cards/pcard_types",
            data : {
                sale_types : types,
                sale_name : name
            }
        });
    }else{
        tishi_alert("请选择类型或填写名称！");
    }
}

//添加套餐卡
function add_pcard(store_id){
    $.ajax({
        async:true,
        type : 'post',
        dataType : 'script',
        url : "/stores/"+ store_id+"/package_cards/add_pcard"
    });
}

//编辑套餐卡
function edit_pcard(id,store_id){
    $.ajax({
        async:true,
        type : 'post',
        dataType : 'script',
        url : "/stores/"+store_id+"/package_cards/"+ id+"/edit_pcard"
    });
}
function check_add(e){
    var name=$("#name").val();
    var base=$("#price").val();
    if (name=="" || name.length==0){
        tishi_alert("请输入套餐卡的名称");
        return false;
    }
    if ( ($("#started_at").val().length == 0 || $("#ended_at").val().length == 0)){
        tishi_alert("请输入套餐卡有效时间和失效时间时间");
        return false;
    }
    if(base == "" || base.length==0 || isNaN(parseFloat(base))){
        tishi_alert("请输入套餐卡的价格");
        return false;
    }
    if($("#add_products").children().length == 0){
        tishi_alert("请选择产品或服务");
        return false;
    }
    $("#add_pcard").submit();
    $(e).removeAttr("onclik");
}

//删除套餐卡
function delete_pcard(pcard_id){
    if(confirm("确定要删除此套餐卡吗？")){
        $.ajax({
            async:true,
            type : 'post',
            dataType : 'json',
            url : "/package_cards/"+pcard_id+"/delete_pcard",
            success:function(data){
                tishi_alert(data.message);
                window.location.reload();
            }
        });
    }
}

function check_station(){
    var status =true
    $("select[name^=select]").each(function(){
        var station_id =$("#stat"+this.id.split("_")[1]+" option:selected").val();
        if(parseInt(station_id)==$("#station_id").val() && $(this).find("option:selected").val()== "0" 　){
            tishi_alert("工位状态正常的必须设置技师");
            status=false;
            return false
        } 
    })
    if(status){
        $("#change_station").submit();
    }

}

function show_pic(){
    var y = 50;
    var doc_width = $(document).width();
    $("input.file").mouseover(function(){
        $(this).parent().find("#card_pic").css("display","block");
    }).mouseout(function(){
        $(this).parent().find("#card_pic").css("display","none");
    }).mousemove(function(e){
        var left = e.pageX-(doc_width-$(".add_tab").width())/2
        if ($(".add_tab").length==0){
            left=e.pageX;
            y=e.pageY;
        }
        $(this).parent().find("#card_pic").css({
            "top":y+"px",
            "left":left+"px"
        })
    })
}