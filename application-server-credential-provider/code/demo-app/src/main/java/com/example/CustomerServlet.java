package com.example;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import javax.sql.DataSource;
import java.util.logging.Logger;

@WebServlet("/customers")
public class CustomerServlet extends HttpServlet {
    private static final Logger logger = Logger.getLogger(CustomerServlet.class.getName());
    private DataSource postgresDS;
    private DataSource cyberArkDS;

    @Override
    public void init() throws ServletException {
        try {
            InitialContext ctx = new InitialContext();
            postgresDS = (DataSource) ctx.lookup("java:comp/env/jdbc/PostgresDS");
            cyberArkDS = (DataSource) ctx.lookup("java:comp/env/jdbc/CyberArkDS");
        } catch (NamingException e) {
            logger.severe("JNDI Lookup failed: " + e.getMessage());
            throw new ServletException("Unable to lookup DataSource", e);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.setContentType("text/html;charset=UTF-8");
        PrintWriter out = response.getWriter();
        
        String sourceParam = request.getParameter("source");
        DataSource dataSource;
        String dataSourceName;
        
        if ("cyberark".equals(sourceParam)) {
            dataSource = cyberArkDS;
            dataSourceName = "CyberArkDS (Managed by ASCP)";
        } else {
            dataSource = postgresDS;
            dataSourceName = "PostgresDS (Standard JNDI)";
        }
        
        logger.info("Processing request using DataSource: " + dataSourceName);

        out.println("<!DOCTYPE html><html><head>");
        out.println("<style>");
        out.println("body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 40px; background-color: #f4f7f6; }");
        out.println("h1 { color: #333; }");
        out.println(".info-box { background: #e7f3fe; border-left: 6px solid #2196F3; margin-bottom: 20px; padding: 10px; }");
        out.println("table { border-collapse: collapse; width: 100%; background: white; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }");
        out.println("th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }");
        out.println("th { background-color: #004a99; color: white; }");
        out.println("tr:nth-child(even) { background-color: #f9f9f9; }");
        out.println("tr:hover { background-color: #f1f1f1; }");
        out.println(".back-link { display: inline-block; margin-top: 20px; text-decoration: none; color: #004a99; font-weight: bold; }");
        out.println("</style></head><body>");

        try (Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT id, first_name, last_name, email, country, signup_date, tier FROM customers LIMIT 50")) {

            out.println("<h1>Company Customer Report</h1>");
            out.println("<div class='info-box'><strong>Active DataSource:</strong> " + dataSourceName + "</div>");

            out.println("<table>");
            out.println("<thead><tr><th>ID</th><th>First Name</th><th>Last Name</th><th>Email</th><th>Country</th><th>Signup Date</th><th>Tier</th></tr></thead><tbody>");

            while (rs.next()) {
                out.println("<tr>");
                out.println("<td>" + rs.getInt("id") + "</td>");
                out.println("<td>" + rs.getString("first_name") + "</td>");
                out.println("<td>" + rs.getString("last_name") + "</td>");
                out.println("<td>" + rs.getString("email") + "</td>");
                out.println("<td>" + rs.getString("country") + "</td>");
                out.println("<td>" + rs.getDate("signup_date") + "</td>");
                out.println("<td>" + rs.getString("tier") + "</td>");
                out.println("</tr>");
            }

            out.println("</tbody></table>");
            out.println("<a href='index.jsp' class='back-link'>Back to Home</a>");
            out.println("</body></html>");

        } catch (Exception e) {
            logger.severe("Database Error: " + e.getMessage());

            out.println("<div style='color: #721c24; background: #f8d7da; padding: 20px; border: 1px solid #f5c6cb; border-radius: 4px;'>");
            out.println("<h2>Database Connection Error</h2>");
            out.println("<p>The system was unable to retrieve data. This might be due to incorrect credential provider configuration or network issues.</p>");
            out.println("<p>Please refer to the server logs for more details.</p>");
            out.println("</div>");
            out.println("<a href='index.jsp' class='back-link'>Back to Home</a>");
            out.println("</body></html>");
        }
    }
}