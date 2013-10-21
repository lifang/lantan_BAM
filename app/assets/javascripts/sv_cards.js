$(document).ready(function(){

})

function date_picker(){
    WdatePicker();
}
function new_sv_card(store_id){                 //新建优惠卡
    $.ajax({
        url: "/stores/"+store_id+"/sv_cards/new",
        type: "get",
        dataType: "script"
    })
}
 function card_type_validate(){  //创建优惠卡时根据选择的卡类型改变表单
     var type = $("#sv_card_types").val();
     if(type == 0){
         $("#sv_card_discount").removeAttr("disabled");
         $("#sv_card_discount").prev().prepend("<span class='red'>*</span>");
         $("#sv_card_price").removeAttr("disabled");
         $("#sv_card_price").prev().prepend("<span class='red'>*</span>");
         $("#setObj").remove();
     }else{
         $("#sv_card_discount").attr("disabled", "disabled");
         $("#sv_card_discount").prev().html("折扣：");
         $("#sv_card_price").attr("disabled", "disabled");
         $("#sv_card_price").prev().html("打折卡金额：");
         $("#sv_card_discount").val("");
         $("#sv_card_price").val("");
         $("#popup_body_area").append("<div id='setObj' class='setObj'><div class='setobj_name'><span class='red'>*</span>项目:</div><div class='setobj_box'>\n\
             <div class='seto_list'><span>充<input id='started_money' name='started_money' type='text' class='input_s'/>元</span>&nbsp;&nbsp;\n\
              <span>送<input id='ended_money' name='ended_money' type='text' class='input_s'/>元</span></div></div></div>")
     } 
 }
 function create_card_validation(){  //创建优惠卡验证
     var type =  $("#sv_card_types").val();
     if($.trim($("#sv_card_name").val()) == null || $.trim($("#sv_card_name").val()) == ""){
             tishi_alert("优惠卡名称不能为空");
             return false;
         };
     if($("#sv_card_img_url").val() == ""){
        tishi_alert("请上传卡的图片!");
        return false;
      }else{
        var img = $("#sv_card_img_url").val();
        var img_suff = img.substring(img.lastIndexOf('.')+1).toLowerCase();
        if(img_suff != "jpg" && img_suff != "png" && img_suff != "gif" && img_suff != "bmp"){
             tishi_alert("请上传格式正确的图片!");
             return false;
        }
      };
      if($.trim($("#sv_card_description").val()) == ""){
        tishi_alert("请描述该卡!");
        return false;
      };
     if(type==0){   //打折卡
         if($.trim($("#sv_card_discount").val()) == ""){
          tishi_alert("请输入折扣!");
          return false;
        }else if(isNaN($("#sv_card_discount").val()) || parseFloat($("#sv_card_discount").val()) > 10 || parseFloat($("#sv_card_discount").val()) < 1){
          tishi_alert("折扣必须在1~10之间的数字!");
          return false;
       };
       if($.trim($("#sv_card_price").val()) == ""){
          tishi_alert("请输入打折卡金额!");
          return false;
      }else if(isNaN($.trim($("#sv_card_price").val()))){
          tishi_alert("请输入有效的打折卡金额!");
          return false;
      }else if(parseFloat($.trim($("#sv_card_price").val()))<=0){
          tishi_alert("金额至少大于零!");
          return false;
      };
     }else if(type==1){ //储值卡
        if($.trim($("#started_money").val()) == ""){
        tishi_alert("请输入充值金额!");
        return false;
      }else if(isNaN($.trim($("#started_money").val())) || parseFloat($.trim($("#started_money").val()))<=0){
        tishi_alert("请输入正确的充值金额!");
        return false;
      };
       if($.trim($("#ended_money").val()) == "" ){
        tishi_alert("请输入赠送金额!");
        return false;
      }else if(isNaN($.trim($("#ended_money").val())) || parseFloat($.trim($("#ended_money").val()))<0){
        tishi_alert("请输入正确的赠送金额!");
        return false;
      }
     }
     $("#new_card_form").submit();
     $("#new_sv_card_btn").attr("disabled", "disabled"); 
 }
 function show_svcard_detail(svcard_id, store_id){    //显示优惠卡详情
     $.ajax({
         url: "/stores/"+store_id+"/sv_cards/"+svcard_id,
         dataType: "script",
         type: "get"
     })
 }
 function edit_card_validation(){    //更新优惠卡验证
    var type =  $("#edit_svcard_form #sv_card_types").val();
    if($.trim($("#sv_card_name").val()) == null || $.trim($("#edit_svcard_form #sv_card_name").val()) == ""){
        tishi_alert("优惠卡名称不能为空");
        return false;
    }
    if($.trim($("#edit_svcard_form #sv_card_description").val()) == null || $.trim($("#edit_svcard_form #sv_card_description").val()) == ""){
        tishi_alert("请描述该卡!");
        return false;
    }
    if($("#edit_svcard_form #sv_card_img_url").val() != ""){
        var img = $("#edit_svcard_form #sv_card_img_url").val();
        var img_suff = img.substring(img.lastIndexOf('.')+1).toLowerCase();
        if(img_suff != "jpg" && img_suff != "png" && img_suff != "gif" && img_suff != "bmp"){
             tishi_alert("请上传格式正确的图片!");
             return false;
        }
      }
    if(type==0){   //打折卡
         if($.trim($("#edit_svcard_form #sv_card_discount").val()) == ""){
          tishi_alert("请输入折扣!");
          return false;
        }else if(isNaN($("#edit_svcard_form #sv_card_discount").val()) || parseFloat($("#edit_svcard_form #sv_card_discount").val()) > 10 || parseFloat($("#edit_svcard_form #sv_card_discount").val()) < 1){
          tishi_alert("折扣必须在1~10之间的数字!");
          return false;
       };
       if($.trim($("#edit_svcard_form #sv_card_price").val()) == ""){
          tishi_alert("请输入打折卡金额!");
          return false;
      }else if(isNaN($.trim($("#edit_svcard_form #sv_card_price").val())) || parseFloat($.trim($("#edit_svcard_form #sv_card_price").val()))<=0){
          tishi_alert("请输入正确的打折卡金额,金额至少大于零!");
          return false;
      };
     }else if(type==1){ //储值卡
       if($.trim($("#edit_svcard_form #started_money").val()) == ""){
        tishi_alert("请输入充值金额!");
        return false;
      }else if(isNaN($.trim($("#edit_svcard_form #started_money").val())) || parseFloat($.trim($("#edit_svcard_form #started_money").val()))<=0){
           tishi_alert("请输入正确的充值金额,金额至少大于零!");
        return false;
      };
       if($.trim($("#edit_svcard_form #ended_money").val()) == ""){
        tishi_alert("请输入赠送金额!");
        return false;
      }else if(isNaN($.trim($("#edit_svcard_form #ended_money").val())) || parseFloat($.trim($("#edit_svcard_form #ended_money").val()))<0){
        tishi_alert("请输入正确的赠送金额!");
        return false;
      }
     }
     $("#edit_svcard_form").submit();
     $("#edit_svcard_btn").attr("disabled", "disabled");
}
function make_billing(c_svc_rel_id, store_id,obj){   //开具发票
    $.ajax({
        url: "/stores/"+store_id+"/sv_cards/make_billing",
        dataType: "json",
        type: "get",
        data: {svcard_id : c_svc_rel_id},
        success: function(data){
            if(data.status==0){
                tishi_alert("操作失败!");
            }else{
                tishi_alert("操作成功!");
                $(obj).parent().text("----");
                $("#is_billing"+c_svc_rel_id).text("是");
                $(obj).remove();
            }
        }
    })
}