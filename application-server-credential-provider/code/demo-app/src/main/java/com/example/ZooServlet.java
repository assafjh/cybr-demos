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
    private DataSource postgresDS;
    private DataSource cyberArkDS;

    @Override
    public void init() throws ServletException {
        try {
            InitialContext ctx = new InitialContext();
            postgresDS = (DataSource) ctx.lookup("java:comp/env/jdbc/PostgresDS");
            cyberArkDS = (DataSource) ctx.lookup("java:comp/env/jdbc/CyberArkDS");
        } catch (NamingException e) {
            throw new ServletException("Unable to lookup DataSource", e);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.setContentType("text/html");
        PrintWriter out = response.getWriter();
        DataSource dataSource = "cyberark".equals(request.getParameter("source")) ? cyberArkDS : postgresDS;
        try (Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT * FROM zoo")) {

            out.println("<html><body>");
            out.println("<h1>Zoo Table</h1>");
            out.println("<table border='1'>");
            out.println("<tr><th>ID</th><th>Name</th><th>Species</th></tr>");

            while (rs.next()) {
                out.println("<tr>");
                out.println("<td>" + rs.getInt("id") + "</td>");
                out.println("<td>" + rs.getString("type") + "</td>");
                out.println("<td>" + rs.getString("caregiver") + "</td>");
                out.println("<td>" + rs.getString("email") + "</td>");
                out.println("</tr>");
            }

            out.println("</table>");
            out.println("</body></html>");

        } catch (Exception e) {
            out.println("Error: " + e.getMessage());
            e.printStackTrace(out);
        }
    }
}

