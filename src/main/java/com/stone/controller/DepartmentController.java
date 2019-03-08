package com.stone.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import com.stone.bean.Department;
import com.stone.bean.Msg;
import com.stone.service.DepartmentService;

/**
 * 处理和部门有关的请求
 *
 */
@Controller
public class DepartmentController {
	
	@Autowired
	private DepartmentService departmentService;
	
	@ResponseBody
	@RequestMapping("/depts")
	public Msg getDepts() {
		List<Department> value = departmentService.getDepts();
		return Msg.success().add("depts", value);
	}
}
