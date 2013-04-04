$(document).ready(function(){
    $("#mat_code").focus();
    $("#mat_code").live('keyup', function(event){
        var codeVal = $(this).val();
        var action_name = $(this).attr("data_action");
        var e = event ? event : window.event
        if(e.keyCode==13){
            $.ajax({
                url:"/get_material",
                dataType:"text",
                data:{
                    code: codeVal,
                    action_name: action_name
                },
                success:function(data) {
                    if(data=="fail"){
                        $(".search_alert").show();
                    }
                    else{
                        $(".search_alert").hide();
                        $(".mat-out-list").find(".newTr_red").removeClass("newTr_red");
                        $(".mat_code").each(function(){
                            if($(this).text()==codeVal){
                                $(this).parent('tr').addClass("newTr_red");
                                var ori_num = parseInt($(this).siblings(".mat_item_num").text());
                                $(this).siblings(".mat_item_num").text(ori_num+1);
                                return false;
                            }
                        });
                        if($(".mat-out-list").find(".newTr_red").length==0){
                            $(".mat-out-list").append(data);
                        }
                        $("#mat_code").val('');
                        $("#mat_code").focus();
                    }
                }
            });
        }
    });
    $("#staff_id").live('change', function(){
        var staff_id = $(this).val();
        $.get("/save_cookies", {
            staff_id: staff_id
        })
        .done(function(data) {})
    })

    setTimeout( function(){
        $('.mat_notice' ).fadeOut();
    }, 3000 );

});

function changeNum(obj){
    var ori_num = $(obj).parent("td").siblings(".mat_item_num").text();
    $(obj).parent("td").siblings(".mat_item_num").hide();
    $(obj).parent("td").prev(".num_box").find("input").val(ori_num).end().show();
}

function hideInput(obj){
    var ori_num = $(obj).val();
    $(obj).parent("td").hide();
    $(obj).parent("td").siblings(".mat_item_num").text(ori_num).show();
}

function removeRow(obj){
    $(obj).parents("tr").remove();
}

function checkNums(){
    var store_id = $("#store_id").val();
    var form_action_url = $("#create_mat_in_form").attr("action");
    var saved_mat_mos = "";
    var mat_in_length = $(".mat-out-list").find("tr").length - 1;
    if(mat_in_length==-1){
        alert('请录入商品！');
    }
    $(".mat-out-list").find("tr").each(function(index){
        var mat_code = $(this).find(".mat_code").text();
        var mo_code = $(this).find(".mo_code").text();
        var num = $(this).find(".mat_item_num").text();
        var mat_name = $(this).find(".mat_name").text();
        var each_item = "";
        $.ajax({
            url:"/stores/" + store_id + "/materials/check_nums",
            dataType:"text",
            type:"GET",
            data:{
                barcode: mat_code,
                mo_code: mo_code,
                num: num,
                store_id: store_id
            },
            success:function(data){
                if(data=="1")
                {
                    if(confirm("【"+mat_name+"】入库数目已经大于订单中的商品数目，仍然要入库吗？")){
                        each_item += mat_code + "_";
                        each_item += mo_code + "_";
                        each_item += num;
                        saved_mat_mos += each_item + ",";
                    }
                }else if(data=="0"){
                    each_item += mat_code + "_";
                    each_item += mo_code + "_";
                    each_item += num;
                    saved_mat_mos += each_item + ",";
                }
                if(mat_in_length == index && saved_mat_mos != "")
                {
                    $.ajax({
                        url: form_action_url,
                        dataType:"text",
                        type:"POST",
                        data:{
                            mat_in_items: saved_mat_mos
                        },
                        success:function(data2){
                            if(data2=="1")
                              { tishi_alert("入库成功！");
                                window.location.replace("/stores/"+ store_id +"/materials_in_outs");
                              }
                        }
                    });
                }
            }
        });
    })


    
}