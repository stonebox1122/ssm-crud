<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>员工列表</title>
<%
	pageContext.setAttribute("APP_PATH", request.getContextPath());
%>
<script type="text/javascript" src="${APP_PATH }/static/js/jquery-1.12.4.min.js"></script>
<link href="${APP_PATH }/static/bootstrap-3.3.7-dist/css/bootstrap.min.css" rel="stylesheet">
<script src="${APP_PATH }/static/bootstrap-3.3.7-dist/js/bootstrap.min.js"></script>
<script type="text/javascript">
	
	var totalRecords,currentPage; 
	//1.页面加载完成后，直接发送一个ajax请求，要到分页数据
	$(function() {
		//去首页
		to_page(1);
		
		//点击新增按钮弹出模态框
		$("#emp_add_modal_btn").click(function() {
			//清除表单数据（表单完整重置（表单数据，表单样式）
			reset_form("#empAddModal form");
			
			$('#empAddModal').modal({
				backdrop:"static"
			});
			
			//发送ajax请求获取部门信息，显示在下拉列表中
			getDepts("#dept_add_select");
		});
		
		//校验用户名是否可用
		$("#empName_add_input").change(function() {
			//发送ajax请求校验用户名是否可用
			var empName = this.value;
			$.ajax({
				url:"${APP_PATH}/checkUser",
				type:"POST",
				data:"empName="+empName,
				success:function(result){
					if(result.code==200){
						show_validate_msg("#empName_add_input","success","用户名可用");
						$("#emp_sava_btn").attr("ajax-va","success");
					}else{
						show_validate_msg("#empName_add_input","error",result.extend.va_msg);
						$("#emp_sava_btn").attr("ajax-va","error");
					}
				}
			})
		});
		
		$("#emp_sava_btn").click(function() {
			//模态框中填写的表单数据提交给服务器进行保存
			//1.先对要提交给服务器的数据进行校验
			if(!validate_add_form()){
				return false;
			}
			
			//2.判断之前的ajax用户名校验是否成功
			if($(this).attr("ajax-va")=="error"){
				return false;
			}
			
			//2.发送ajax请求保存员工
			$.ajax({
				url:"${APP_PATH}/emp",
				type:"POST",
				data:$("#empAddModal form").serialize(),
				success:function(result){
					//alert(result.msg);
					if(result.code==200){
						//员工保存成功后，关闭模态框
						$('#empAddModal').modal('hide');
						
						//发送ajax请求显示最后一页的数据
						to_page(totalRecords);
					}else{
						//显示失败信息
						//console.log(result);
						if(undefined != result.extend.errorField.email){
							//显示邮箱错误信息
							show_validate_msg("#email_add_input","error",result.extend.errorField.email);
						};
						if(undefined != result.extend.errorField.empName){
							//显示姓名错误信息
							show_validate_msg("#empName_add_input","error",result.extend.errorField.empName);
						};
					}
				}
			})
		});
		
		//创建修改按钮的点击事件
		$(document).on("click",".edit_btn",function(){
			//查出部门信息，并显示部门列表
			getDepts("#dept_update_select");
			//查出员工信息，并显示员工信息
			getEmp($(this).attr("edit-id"));
			
			//把员工的id传递给模态框的更新按钮
			$("#emp_update_btn").attr("edit-id",$(this).attr("edit-id"));
			$('#empUpdateModal').modal({
				backdrop:"static"
			});
		})
		
		
		//点击更新，更新员工信息
		$("#emp_update_btn").click(function() {
			//验证邮箱是否合法
			var email = $("#email_update_input").val();
			var regEmail = /^([a-z0-9_\.-]+)@([\da-z\.-]+)\.([a-z\.]{2,6})$/;
			if(!regEmail.test(email)){
				show_validate_msg("#email_update_input","error","邮箱格式不正确");
				return false;
			}else{
				show_validate_msg("#email_update_input","success","");
			};
			
			//发送ajax请求，保存更新的数据
			$.ajax({
				url:"${APP_PATH}/emp/"+$(this).attr("edit-id"),
				type:"PUT",
				data:$("#empUpdateModal form").serialize(),
				success:function(result){
					//关闭模态框
					$('#empUpdateModal').modal('hide');
					
					//回到本页面
					to_page(currentPage);
				}
			});
			
		})
		
		//单个删除
		$(document).on("click",".delete_btn",function(){
			//弹出是否删除对话框
			var empName = $(this).parents("tr").find("td:eq(2)").text();
			var empId = $(this).attr("del-id");
			if(confirm("确认删除【"+empName+"】吗？")){
				//确认，发送ajax请求进行删除
				$.ajax({
					url:"${APP_PATH}/emp/"+empId,
					type:"DELETE",
					success:function(result){
						alert(result.msg);
						to_page(currentPage);
					}
				})
			};
		});
		
		
		//复选框的全选/全不选
		$("#check_all").click(function() {
			//attr获取checked是undefined
			//alert($(this).attr("checked"));
			//使用prop获取dom原生的属性，attr获取自定义的属性
			//alert($(this).prop("checked"));
			$(".check_item").prop("checked",$(this).prop("checked"));
		})
		
		//各条记录上的复选框点击事件
		$(document).on("click",".check_item",function(){
			//判断当前是否选择了页面上的所有复选框
			var flag = $(".check_item:checked").length==$(".check_item").length;
			$("#check_all").prop("checked",flag);
		})
		
		
		//点击全部删除就批量删除
		$("#emp_delete_all_btn").click(function() {
			var empNames = "";
			var del_idstr = "";
			$.each($(".check_item:checked"),function(){
				empNames += $(this).parents("tr").find("td:eq(2)").text()+",";
				del_idstr += $(this).parents("tr").find("td:eq(1)").text()+"-";
			})
			//去除empNames最后的逗号
			empNames = empNames.substring(0,empNames.length-1);
			del_idstr = del_idstr.substring(0,del_idstr.length-1);
			if(confirm("确认删除【"+empNames+"】吗？")){
				//发送ajax请求删除
				$.ajax({
					url:"${APP_PATH}/emp/"+del_idstr,
					type:"DELETE",
					success:function(result){
						alert(result.msg);
						to_page(currentPage);
						$("#check_all").prop("checked",false);
					}
				})
			}
		})
		
	})
	
	function getEmp(id){
		$.ajax({
			url:"${APP_PATH}/emp/"+id,
			type:"GET",
			success:function(result){
				var empData = result.extend.emp;
				$("#empName_update_static").text(empData.empName);
				$("#email_update_input").val(empData.email);
				$("#empUpdateModal input[name=gender]").val([empData.gender]);
				$("#empUpdateModal select").val([empData.dId]);
			}
		})
	}
	
	function getDepts(ele){
		//先清空之前下拉列表信息
		$(ele).empty();
		$.ajax({
			url:"${APP_PATH}/depts",
			type:"GET",
			success:function(result){
				//显示部门信息在下拉列表中
				$.each(result.extend.depts,function(){
					var optionEle = $("<option></option>").append(this.deptName).attr("value",this.deptId);
					optionEle.appendTo(ele);
				})
			}
		})
	}
	
	function to_page(pn){
		$.ajax({
			url:"${APP_PATH}/emps",
			data:"pn="+pn,
			type:"GET",
			success:function(result){
				//console.log(result);
				//1.解析并显示员工数据
				build_emps_table(result);
				//2.解析并显示分页信息
				build_page_info(result);
				//3.解析并显示分页条信息
				build_page_nav(result);
			}
		})
	}
	
	//解析并显示员工数据
	function build_emps_table(result){
		//先清空table表格
		$("#emps_table tbody").empty();
		var emps = result.extend.pageInfo.list;
		$.each(emps,function(index,item){
			var checkBoxTd = $("<td><input type='checkbox' class='check_item'/></td>");
			var empIdTd = $("<td></td>").append(item.empId);
			var empNameTd = $("<td></td>").append(item.empName);
			var genderTd = $("<td></td>").append(item.gender=="M"?"男":"女");
			var emailTd = $("<td></td>").append(item.email);
			var deptNameTd = $("<td></td>").append(item.department.deptName);
			var editBtn = $("<button></button>")
				.addClass("btn btn-primary btn-sm edit_btn")
				.append($("<span></span>").addClass("glyphicon glyphicon-pencil"))
				.append("编辑");
			//为编辑按钮添加一个自定义的属性，来表示当前员工id
			editBtn.attr("edit-id",item.empId);
			var delBtn = $("<button></button>")
				.addClass("btn btn-danger btn-sm delete_btn")
				.append($("<span></span>").addClass("glyphicon glyphicon-trash"))
				.append("删除");
			//为删除按钮添加一个自定义的属性，来表示当前员工id
			delBtn.attr("del-id",item.empId);
			var btnTd = $("<td></td>").append(editBtn).append(" ").append(delBtn);
			$("<tr></tr>").append(checkBoxTd).
				append(empIdTd)
				.append(empNameTd)
				.append(genderTd)
				.append(emailTd)
				.append(deptNameTd)
				.append(btnTd)
				.appendTo("#emps_table tbody");
		})
	}
	
	//解析并显示分页信息
	function build_page_info(result){
		$("#page_info_area").empty();
		var pageNum = result.extend.pageInfo.pageNum;
		var pages = result.extend.pageInfo.pages;
		var total = result.extend.pageInfo.total;
		totalRecords = total;
		currentPage = pageNum;
		$("#page_info_area").append("当前"+pageNum+"页，共"+pages+"页，共"+total+"条记录");
	}
	
	//解析并显示分页条，并添加点击事件
	function build_page_nav(result){
		$("#page_nav_area").empty();
		var ul = $("<ul></ul>").addClass("pagination");
		
		var firstPageLi = $("<li></li>").append($("<a></a>").append("首页").attr("href","#"));
		var prePageLi = $("<li></li>").append($("<a></a>").append($("<span></span>").append("&laquo;")).attr("href","#"));
		if(result.extend.pageInfo.hasPreviousPage == false){
			firstPageLi.addClass("disabled");
			prePageLi.addClass("disabled");
		}else{
			firstPageLi.click(function() {
				to_page(1);
			})
			prePageLi.click(function() {
				to_page(result.extend.pageInfo.pageNum-1);
			})
		}
		ul.append(firstPageLi).append(prePageLi);
		
		$.each(result.extend.pageInfo.navigatepageNums,function(index,item){
			var numLi = $("<li></li>").append($("<a></a>").append(item).attr("href","#"));
			if(result.extend.pageInfo.pageNum == item){
				numLi.addClass("active");
			}
			numLi.click(function() {
				to_page(item);
			})
			ul.append(numLi);
		});
		
		var nextPageLi = $("<li></li>").append($("<a></a>").append($("<span></span>").append("&raquo;")).attr("href","#"));
		var lastPageLi = $("<li></li>").append($("<a></a>").append("末页").attr("href","#"));
		if(result.extend.pageInfo.hasNextPage == false){
			nextPageLi.addClass("disabled");
			lastPageLi.addClass("disabled");
		}else{
			nextPageLi.click(function() {
				to_page(result.extend.pageInfo.pageNum+1);
			})
			lastPageLi.click(function() {
				to_page(result.extend.pageInfo.pages);
			})
		}
		ul.append(nextPageLi).append(lastPageLi);
		
		var navEle = $("<nav></nav>").append(ul)
		navEle.appendTo("#page_nav_area");
	}
	
	//校验表单数据
	function validate_add_form(){
		//校验姓名
		var empName = $("#empName_add_input").val();
		var regName = /(^[a-zA-Z0-9_-]{6,16}$)|(^[\u2E80-\u9FFF]{2,6})/;
		if(!regName.test(empName)){
			//alert("用户名可以是2-5位中文或者6-16位英文和数字的组合");
			//应该清空这个元素之前的样式
			show_validate_msg("#empName_add_input","error","用户名可以是2-5位中文或者6-16位英文和数字的组合");
			return false;
		}else{
			show_validate_msg("#empName_add_input","success","");
		};
		
		//校验邮箱
		var email = $("#email_add_input").val();
		var regEmail = /^([a-z0-9_\.-]+)@([\da-z\.-]+)\.([a-z\.]{2,6})$/;
		if(!regEmail.test(email)){
			//alert("邮箱格式不正确");
			show_validate_msg("#email_add_input","error","邮箱格式不正确");
			return false;
		}else{
			show_validate_msg("#email_add_input","success","");
		};
		return true;
	}
	
	//显示校验结果的提示信息
	function show_validate_msg(ele,status,msg){
		//清除当前元素校验状态
		$(ele).parent().removeClass("has-success has-error");
		$(ele).next("span").text("");
		if("success"==status){
			$(ele).parent().addClass("has-success");
			$(ele).next("span").text(msg);
		}else if("error"==status){
			$(ele).parent().addClass("has-error");
			$(ele).next("span").text(msg);
		}
	}
	
	//清空表单数据和样式
	function reset_form(ele){
		//清空表单数据
		$(ele)[0].reset();
		
		//清空表单样式
		$(ele).find("*").removeClass("has-success has-error");
		$(ele).find(".help-block").text("");
	}
	
	
	
</script>
</head>
<body>
	
	<!-- 员工添加的模态框 -->
	<div class="modal fade" id="empAddModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel">
	  <div class="modal-dialog" role="document">
	    <div class="modal-content">
	      <div class="modal-header">
	        <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
	        <h4 class="modal-title" id="myModalLabel">员工添加</h4>
	      </div>
	      <div class="modal-body">
	      	<form class="form-horizontal">
			  <div class="form-group">
			    <label for="empName_add_input" class="col-sm-2 control-label">姓名</label>
			    <div class="col-sm-10">
			      <input type="text" name="empName" class="form-control" id="empName_add_input" placeholder="张三">
			      <span class="help-block"></span>
			    </div>
			  </div>
			  <div class="form-group">
			    <label for="email_add_input" class="col-sm-2 control-label">邮箱</label>
			    <div class="col-sm-10">
			      <input type="text" name="email" class="form-control" id="email_add_input" placeholder="zhangsan@sina.com">
			      <span class="help-block"></span>
			    </div>
			  </div>
			  <div class="form-group">
			    <label class="col-sm-2 control-label">性别</label>
			    <div class="col-sm-10">
			    	<label class="radio-inline">
					  <input type="radio" name="gender" id="genderM_add_input" value="M" checked="checked"> 男
					</label>
					<label class="radio-inline">
					  <input type="radio" name="gender" id="genderF_add_input" value="F"> 女
					</label>
			    </div>
			  </div>
			  <div class="form-group">
			    <label class="col-sm-2 control-label">部门</label>
			    <div class="col-sm-4">
			    	<select class="form-control" name="dId" id="dept_add_select">
					</select>
			    </div>
			  </div>
			</form>
	      </div>
	      <div class="modal-footer">
	        <button type="button" class="btn btn-default" data-dismiss="modal">关闭</button>
	        <button type="button" class="btn btn-primary" id="emp_sava_btn">保存</button>
	      </div>
	    </div>
	  </div>
	</div>
	
	<!-- 员工修改的模态框 -->
	<div class="modal fade" id="empUpdateModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel">
	  <div class="modal-dialog" role="document">
	    <div class="modal-content">
	      <div class="modal-header">
	        <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
	        <h4 class="modal-title" id="myModalLabel">员工修改</h4>
	      </div>
	      <div class="modal-body">
	      	<form class="form-horizontal">
			  <div class="form-group">
			    <label for="empName_add_input" class="col-sm-2 control-label">姓名</label>
			    <div class="col-sm-10">
			      <p class="form-control-static" id="empName_update_static"></p>
			    </div>
			  </div>
			  <div class="form-group">
			    <label for="email_add_input" class="col-sm-2 control-label">邮箱</label>
			    <div class="col-sm-10">
			      <input type="text" name="email" class="form-control" id="email_update_input" placeholder="zhangsan@sina.com">
			      <span class="help-block"></span>
			    </div>
			  </div>
			  <div class="form-group">
			    <label class="col-sm-2 control-label">性别</label>
			    <div class="col-sm-10">
			    	<label class="radio-inline">
					  <input type="radio" name="gender" id="genderM_update_input" value="M" checked="checked"> 男
					</label>
					<label class="radio-inline">
					  <input type="radio" name="gender" id="genderF_update_input" value="F"> 女
					</label>
			    </div>
			  </div>
			  <div class="form-group">
			    <label class="col-sm-2 control-label">部门</label>
			    <div class="col-sm-4">
			    	<select class="form-control" name="dId" id="dept_update_select">
					</select>
			    </div>
			  </div>
			</form>
	      </div>
	      <div class="modal-footer">
	        <button type="button" class="btn btn-default" data-dismiss="modal">关闭</button>
	        <button type="button" class="btn btn-primary" id="emp_update_btn">更新</button>
	      </div>
	    </div>
	  </div>
	</div>
	
	<!-- 搭建显示页面 -->
	<div class="container">
		<!-- 标题 -->
		<div class="row">
			<div class="col-md-12">
				<h1>SSM-CURD</h1>
			</div>
		</div>
		<!-- 按钮 -->
		<div class="row">
			<div class="col-md-4 col-md-offset-8">
				<button type="button" class="btn btn-primary" id="emp_add_modal_btn">新增</button>
				<button type="button" class="btn btn-danger" id="emp_delete_all_btn">删除</button>
			</div>
		</div>
		<!-- 显示表格数据 -->
		<div class="row">
			<div class="col-md-12">
				<table class="table table-hover" id="emps_table">
					<thead>
						<tr>
							<th>
								<input type="checkbox" id="check_all">
							</th>
							<th>编号</th>
							<th>姓名</th>
							<th>性别</th>
							<th>邮件</th>
							<th>部门</th>
							<th>操作</th>
						</tr>
					</thead>
					<tbody>
					</tbody>
				</table>
			</div>
		</div>
		<!-- 显示分页信息 -->
		<div class="row">
			<!-- 分页文字信息 -->
			<div class="col-md-6" id="page_info_area"></div>
			<!-- 分页条信息 -->
			<div class="col-md-6" id="page_nav_area"></div>
		</div>
	</div>
</body>
</html>