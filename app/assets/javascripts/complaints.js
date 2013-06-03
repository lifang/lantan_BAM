function choose_brand(capital_div, car_brands, car_models) {
    if ($.trim($(capital_div).val()) != "") {
        $.ajax({
            async:true,
            dataType:'json',
            data:{
                capital_id : $(capital_div).val()
            },
            url:"/customers/get_car_brands",
            type:'post',
            success : function(data) {
                if (data != null && data != undefined) {
                    $(car_brands +" option").remove();
                    $(car_brands).append("<option value=''>--</option>");
                    $(car_models +" option").remove();
                    $(car_models).append("<option value=''>--</option>");
                    for (var i=0; i<data.length; i++) {
                        $(car_brands).append("<option value='"+ data[i].id + "'>"+ data[i].name + "</option>");
                    }
                }
            }
        })
    }
}

function choose_model(car_brands, car_models) {
    if ($.trim($(car_brands).val()) != "") {
        $.ajax({
            async:true,
            dataType:'json',
            data:{
                brand_id : $(car_brands).val()
            },
            url:"/customers/get_car_models",
            type:'post',
            success : function(data) {
                if (data != null && data != undefined) {
                    $(car_models + " option").remove();
                    $(car_models).append("<option value=''>--</option>");
                    for (var i=0; i<data.length; i++) {
                        $(car_models).append("<option value='"+ data[i].id + "'>"+ data[i].name + "</option>");
                    }
                }
            }
        })
    }
}


