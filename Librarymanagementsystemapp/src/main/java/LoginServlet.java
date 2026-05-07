import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        String username = request.getParameter("username");
        String password = request.getParameter("password");

        try {

            Class.forName("org.postgresql.Driver");

            Connection con = DriverManager.getConnection(
                    "jdbc:postgresql://localhost:5432/librarydb",
                    "postgres",
                    "Jagdish@2003");

            PreparedStatement ps = con.prepareStatement(
                    "SELECT * FROM login WHERE username=? AND password=?");

            ps.setString(1, username);
            ps.setString(2, password);

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {

               
                HttpSession session = request.getSession();
                session.setAttribute("user", username);

                response.sendRedirect("Dbcon.jsp");

            } else {

                
                response.sendRedirect("addbook.html?error=Invalid Username or Password");

            }

            con.close();

        } catch (Exception e) {
            response.sendRedirect("Dbcon.jsp?error=Database Error");
        }
    }
}