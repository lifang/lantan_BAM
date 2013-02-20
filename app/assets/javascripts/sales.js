
//发布活动验证
function publish_sale(){
    var name=$("#sale_title").val();
    var disc=$("#s_disc input[name='discount']:checked").val();
    var time=$("#s_time input[name='disc_time']:checked").val();
    var subsidy =$("#s_sub input[name='subsidy']:checked").val();
    var pic_format=["png",'gif',"jpg","bmp","pcx","tiff","jpeg","tga","eps","hdr","tif"]
    var img=$("#img_url").val();
    if (name=="" || name.length==0){
        alert("请输入本次活动的标题")
        return false;
    }
    if($("#add_products").children().length == 0){
        alert("请选择产品或服务");
        return false;
    }
    if (disc == undefined){
        alert("请选择优惠类型");
        return false;
    }
    if (parseInt(disc)==1 && $("#disc_"+disc).val().length==0){
        alert("请填写优惠的金额");
        return false;
    }
    if (parseInt(disc)==0 && $("#disc_"+disc).val().length==0){
        alert("请填写打折的折扣");
        return false;
    }
    if (time == undefined){
        alert("请选择时间的类型")
        return false;
    }
    if (parseInt(time)==0 && ($("#started_at").val().length == 0 || $("#ended_at").val().length == 0)){
        alert("请输入活动开始和结束的时间");
        return false;
    }
    if ($("#disc_car_nums").val() == " " || $("#disc_car_nums").val().length==0 ){
        alert("请参加活动的总车辆数");
        return false;
    }
    if (subsidy == undefined){
        alert("请选择是否需要总店补贴")
        return false;
    }
    if ((img != "" || img.length !=0) && pic_format.indexOf(img.split(".")[img.split(".").length-1])== -1){
        alert("请选择正确格式的图片！")
    }
    if (parseInt(subsidy)==1 && $("#sub_content").val().length == 0){
        alert("请输入补贴金额");
        return false;
    }

    $("#intro").val(editor.html());
    $("#one_sale").submit();
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
                alert(data.message);
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
                alert(data.message);
                window.location.reload();
            }
        });
    }
}


