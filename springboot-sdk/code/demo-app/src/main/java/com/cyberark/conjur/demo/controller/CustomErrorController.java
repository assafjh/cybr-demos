package com.example.demo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.boot.web.error.ErrorAttributeOptions;
import org.springframework.boot.web.servlet.error.ErrorAttributes;
import org.springframework.boot.web.servlet.error.ErrorController;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.context.request.ServletWebRequest;

import java.util.Map;

@Controller
public class CustomErrorController implements ErrorController {

    private final ErrorAttributes errorAttributes;

    public CustomErrorController(ErrorAttributes errorAttributes) {
        this.errorAttributes = errorAttributes;
    }

    @RequestMapping("/custom-error")
    public String handleError(HttpServletRequest request, Model model) {
        // Retrieve error details
        ServletWebRequest webRequest = new ServletWebRequest(request);
        Map<String, Object> attributes =
            errorAttributes.getErrorAttributes(webRequest, ErrorAttributeOptions.defaults());

        // Extract desired fields (status, error, message, etc.)
        Object statusCode = attributes.get("status");
        Object error = attributes.get("error");
        Object message = attributes.get("message");
        Object timestamp = attributes.get("timestamp");
        Object path = attributes.get("path");

        // Populate the model
        model.addAttribute("status", statusCode);
        model.addAttribute("error", error);
        model.addAttribute("message", message);
        model.addAttribute("timestamp", timestamp);
        model.addAttribute("path", path);

        return "customError";
    }
}
