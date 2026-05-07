<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>

<%
String user = (String) session.getAttribute("user");
if (user == null) {
    response.sendRedirect("login.jsp");
    return;
}
response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
response.setHeader("Pragma", "no-cache");
response.setDateHeader("Expires", 0);
Connection con = null;
PreparedStatement ps = null;
Statement st = null;
ResultSet rs = null;
String message = "";

try {

    Class.forName("org.postgresql.Driver");
    con = DriverManager.getConnection(
        "jdbc:postgresql://localhost:5432/librarydb",
        "postgres",
        "Jagdish@2003"
    );

    String action = request.getParameter("action");

    if ("add".equals(action)) {
        ps = con.prepareStatement(
            "INSERT INTO books(book_name, author, quantity) VALUES (?, ?, ?)"
        );
        ps.setString(1, request.getParameter("book"));
        ps.setString(2, request.getParameter("author"));
        ps.setInt(3, Integer.parseInt(request.getParameter("qty")));
        ps.executeUpdate();
        ps.close();
        message = "Book Added Successfully ✅";
    }

    if ("update".equals(action)) {
        ps = con.prepareStatement(
            "UPDATE books SET book_name=?, author=?, quantity=? WHERE id=?"
        );
        ps.setString(1, request.getParameter("book"));
        ps.setString(2, request.getParameter("author"));
        ps.setInt(3, Integer.parseInt(request.getParameter("qty")));
        ps.setInt(4, Integer.parseInt(request.getParameter("id")));
        ps.executeUpdate();
        ps.close();
        message = "Book Updated Successfully ✏️";
    }

    if ("delete".equals(action)) {
        ps = con.prepareStatement("DELETE FROM books WHERE id=?");
        ps.setInt(1, Integer.parseInt(request.getParameter("id")));
        ps.executeUpdate();
        ps.close();
        message = "Book Deleted Successfully ❌";
    }

    if ("issue".equals(action)) {
        String student = request.getParameter("student");
        String bookName = request.getParameter("book");

        ps = con.prepareStatement(
            "UPDATE books SET quantity = quantity - 1 WHERE book_name=? AND quantity > 0"
        );
        ps.setString(1, bookName);
        int rows = ps.executeUpdate();
        ps.close();

        if (rows > 0) {
            ps = con.prepareStatement(
                "INSERT INTO issue_book(student_name, book_name) VALUES (?, ?)"
            );
            ps.setString(1, student);
            ps.setString(2, bookName);
            ps.executeUpdate();
            ps.close();
            message = "Book Issued Successfully 📚";
        } else {
            message = "Book Not Available ❌";
        }
    }

    if ("deleteIssue".equals(action)) {
        int issueId = Integer.parseInt(request.getParameter("id"));

        ps = con.prepareStatement("SELECT book_name FROM issue_book WHERE id=?");
        ps.setInt(1, issueId);
        ResultSet temp = ps.executeQuery();

        String bookName = null;
        if (temp.next()) bookName = temp.getString("book_name");
        temp.close();
        ps.close();

        if (bookName != null) {
            ps = con.prepareStatement(
                "UPDATE books SET quantity = quantity + 1 WHERE book_name=?"
            );
            ps.setString(1, bookName);
            ps.executeUpdate();
            ps.close();
        }

        ps = con.prepareStatement("DELETE FROM issue_book WHERE id=?");
        ps.setInt(1, issueId);
        ps.executeUpdate();
        ps.close();

        message = "Book Returned Successfully 🔄";
    }

} catch(Exception e) {
    message = "Error: " + e.getMessage();
}
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Library Management System</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</head>

<body class="p-4" style="background:#f4f6f9;">

<div class="d-flex justify-content-between mb-4">
    <div>
        <h2>Library Management System</h2>
        <h5>Welcome <%= user %></h5>
    </div>
    <div>
        <a href="LogoutServlet" class="btn btn-danger">Logout</a>
    </div>
</div>

<% if(!message.isEmpty()) { %>
<div class="alert alert-info"><%= message %></div>
<% } %>

<button class="btn btn-success mb-3" data-bs-toggle="modal" data-bs-target="#addModal">+ Add Book</button>
<button class="btn btn-primary mb-3" data-bs-toggle="modal" data-bs-target="#issueModal">Issue Book</button>

<h3>Books List</h3>

<table class="table table-bordered bg-white">
<tr><th>ID</th><th>Book</th><th>Author</th><th>Qty</th><th>Action</th></tr>

<%
try {
    st = con.createStatement();
    rs = st.executeQuery("SELECT * FROM books ORDER BY id");

    while(rs.next()) {
%>
<tr>
<td><%= rs.getInt("id") %></td>
<td><%= rs.getString("book_name") %></td>
<td><%= rs.getString("author") %></td>
<td><%= rs.getInt("quantity") %></td>
<td>
<button class="btn btn-warning btn-sm"
        data-bs-toggle="modal"
        data-bs-target="#editModal"
        onclick="setEditData('<%= rs.getInt("id") %>','<%= rs.getString("book_name") %>','<%= rs.getString("author") %>','<%= rs.getInt("quantity") %>')">
Edit</button>

<form method="post" style="display:inline;">
<input type="hidden" name="action" value="delete">
<input type="hidden" name="id" value="<%= rs.getInt("id") %>">
<button class="btn btn-danger btn-sm">Delete</button>
</form>
</td>
</tr>
<%
    }
} catch(Exception e) {}
%>
</table>

<h3>Issued Books</h3>
<table class="table table-bordered bg-white">
<tr><th>ID</th><th>Student</th><th>Book</th><th>Action</th></tr>

<%
try {
    Statement st2 = con.createStatement();
    ResultSet rs2 = st2.executeQuery("SELECT * FROM issue_book ORDER BY id DESC");

    while(rs2.next()) {
%>
<tr>
<td><%= rs2.getInt("id") %></td>
<td><%= rs2.getString("student_name") %></td>
<td><%= rs2.getString("book_name") %></td>
<td>
<form method="post">
<input type="hidden" name="action" value="deleteIssue">
<input type="hidden" name="id" value="<%= rs2.getInt("id") %>">
<button class="btn btn-success btn-sm">Return</button>
</form>
</td>
</tr>
<%
    }
    rs2.close();
    st2.close();
} catch(Exception e) {}
finally {
    if(rs!=null) rs.close();
    if(st!=null) st.close();
    if(con!=null) con.close();
}
%>
</table>

<!-- ADD MODAL -->
<div class="modal fade" id="addModal">
<div class="modal-dialog">
<div class="modal-content">
<form method="post">
<div class="modal-header">
<h5>Add Book</h5>
<button type="button" class="btn-close" data-bs-dismiss="modal"></button>
</div>
<div class="modal-body">
<input type="hidden" name="action" value="add">
<input type="text" name="book" class="form-control mb-2" placeholder="Enter Book Name" required>
<input type="text" name="author" class="form-control mb-2" placeholder="Enter Author Name" required>
<input type="number" name="qty" class="form-control mb-2" placeholder="Enter Quantity" required>
</div>
<div class="modal-footer">
<button class="btn btn-success">Save</button>
</div>
</form>
</div>
</div>
</div>

<!-- ISSUE MODAL -->
<div class="modal fade" id="issueModal">
<div class="modal-dialog">
<div class="modal-content">
<form method="post">
<div class="modal-header">
<h5>Issue Book</h5>
<button type="button" class="btn-close" data-bs-dismiss="modal"></button>
</div>
<div class="modal-body">
<input type="hidden" name="action" value="issue">
<input type="text" name="student" class="form-control mb-2" placeholder="Enter Student Name" required>
<input type="text" name="book" class="form-control mb-2" placeholder="Enter Book Name" required>
</div>
<div class="modal-footer">
<button class="btn btn-primary">Issue</button>
</div>
</form>
</div>
</div>
</div>

<!-- EDIT MODAL -->
<div class="modal fade" id="editModal">
<div class="modal-dialog">
<div class="modal-content">
<form method="post">
<div class="modal-header">
<h5>Edit Book</h5>
<button type="button" class="btn-close" data-bs-dismiss="modal"></button>
</div>
<div class="modal-body">
<input type="hidden" name="action" value="update">
<input type="hidden" name="id" id="editId">
<input type="text" name="book" id="editBook" class="form-control mb-2" required>
<input type="text" name="author" id="editAuthor" class="form-control mb-2" required>
<input type="number" name="qty" id="editQty" class="form-control mb-2" required>
</div>
<div class="modal-footer">
<button class="btn btn-primary">Update</button>
</div>
</form>
</div>
</div>
</div>

<script>
function setEditData(id, book, author, qty) {
document.getElementById("editId").value = id;
document.getElementById("editBook").value = book;
document.getElementById("editAuthor").value = author;
document.getElementById("editQty").value = qty;
}
</script>

</body>
</html>