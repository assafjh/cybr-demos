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

@WebServlet("/zoo")
public class ZooServlet extends HttpServlet {
    private DataSource dataSource;
    private String dataSourceName;

    @Override
    public void init() throws ServletException {
        // Default DataSource name
        dataSourceName = "jdbc/PostgresDS";
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // Check for the source parameter
        String source = request.getParameter("source");
        if (source != null) {
            dataSourceName = "jdbc/" + source;
        }

        try {
            InitialContext ctx = new InitialContext();
            dataSource = (DataSource) ctx.lookup("java:comp/env/" + dataSourceName);
        } catch (NamingException e) {
            throw new ServletException("Unable to lookup DataSource", e);
        }

        response.setContentType("text/html");
        PrintWriter out = response.getWriter();
        out.println("<html><body>");
        out.println("<h1>Using DataSource: " + dataSourceName + "</h1>");
        out.println("<h1>Zoo Table</h1>");
        out.println("<table border='1'>");
        out.println("<tr><th>ID</th><th>Type</th><th>Caregiver</th><th>Email</th></tr>");

        try (Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT * FROM zoo")) {

            while (rs.next()) {
                out.println("<tr>");
                out.println("<td>" + rs.getInt("id") + "</td>");
                out.println("<td>" + rs.getString("type") + "</td>");
                out.println("<td>" + rs.getString("caregiver") + "</td>");
                out.println("<td>" + rs.getString("email") + "</td>");
                out.println("</tr>");
            }

        } catch (Exception e) {
            out.println("Error: " + e.getMessage());
            e.printStackTrace(out);
        }

        out.println("</table>");
        out.println("</body></html>");
    }
}

