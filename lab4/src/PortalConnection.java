
import org.json.JSONObject;
import org.postgresql.util.PSQLException;

import java.sql.*; // JDBC stuff.
import java.util.Properties;

public class PortalConnection {

    // Set this to e.g. "portal" if you have created a database named portal
    // Leave it blank to use the default database of your database user
    static final String DBNAME = "";
    // For connecting to the portal database on your local machine
    static final String DATABASE = "jdbc:postgresql://localhost/" + DBNAME;
    static final String USERNAME = "lab3";
    static final String PASSWORD = "lab3";

    // For connecting to the chalmers database server (from inside chalmers)
    // static final String DATABASE = "jdbc:postgresql://brage.ita.chalmers.se/";
    // static final String USERNAME = "tda357_nnn";
    // static final String PASSWORD = "yourPasswordGoesHere";


    // This is the JDBC connection object you will be using in your methods.
    private Connection conn;

    public PortalConnection() throws SQLException, ClassNotFoundException {
        this(DATABASE, USERNAME, PASSWORD);
    }

    // Initializes the connection, no need to change anything here
    public PortalConnection(String db, String user, String pwd) throws SQLException, ClassNotFoundException {
        Class.forName("org.postgresql.Driver");
        Properties props = new Properties();
        props.setProperty("user", user);
        props.setProperty("password", pwd);
        conn = DriverManager.getConnection(db, props);
    }

    // Register a student on a course, returns a tiny JSON document (as a String)
    public String register(String student, String courseCode) {
        try (PreparedStatement registerStudent = conn.prepareStatement("INSERT INTO registrations VALUES (?, ?);")) {
            conn.setAutoCommit(true);
            registerStudent.setString(1, student);
            registerStudent.setString(2, courseCode);
            registerStudent.executeUpdate();
            return "{\"success\": true}";
        } catch (SQLException e) {
            return String.format("{\"success\": false, \"error\": \"%s\"}", getError(e));
        }
    }

    // Unregister a student from a course, returns a tiny JSON document (as a String)
    public String unregister(String student, String courseCode) {
        try (PreparedStatement registerStudent = conn.prepareStatement("DELETE FROM registrations WHERE student=? AND course=?;")) {
            conn.setAutoCommit(true);
            registerStudent.setString(1, student);
            registerStudent.setString(2, courseCode);
            registerStudent.executeUpdate();
            return "{\"success\": true}";
        } catch (SQLException e) {
            return String.format("{\"success\": false, \"error\": \"%s\"}", getError(e));
        }
    }

    // Return a JSON document containing lots of information about a student, it should validate against the schema found in information_schema.json
    public String getInfo(String student) throws SQLException {
		
		JSONObject obj = new JSONObject();

        try (PreparedStatement st = conn.prepareStatement(
                "SELECT * FROM basicinformation JOIN pathtograduation on idnr=student WHERE idnr=?;"
        );) {
            st.setString(1, student);
            ResultSet rs = st.executeQuery();

            if (rs.next()) {
                obj.put("student", rs.getString(1));
                obj.put("name", rs.getString(2));
                obj.put("login", rs.getString(3));
                obj.put("program", rs.getString(4));
                obj.put("branch", rs.getString(5));
				
                obj.put("seminarCourses", rs.getInt(11));
                obj.put("mathCredits", rs.getDouble(9));
                obj.put("researchCredits", rs.getDouble(10));
                obj.put("totalCredits", rs.getDouble(7));
                obj.put("canGraduate", rs.getBoolean(12));
				
            }
			rs.close();
        }
		
		try (PreparedStatement st = conn.prepareStatement(
                "SELECT name, code, courses.credits, grade FROM finishedCourses JOIN courses on course=code WHERE student=?;"
        );) {
            st.setString(1, student);
            ResultSet rs = st.executeQuery();
            while (rs.next()) {
				JSONObject arrObj = new JSONObject();
                arrObj.put("course", rs.getString(1));
                arrObj.put("code", rs.getString(2));
                arrObj.put("credits", rs.getDouble(3));
                arrObj.put("grade", rs.getString(4));
				obj.append("finished",arrObj);
            }
			rs.close();
        }
		
		try (PreparedStatement st = conn.prepareStatement(
                "SELECT name, code, status, place from registrations JOIN courses on course=code LEFT JOIN coursequeuepositions on coursequeuepositions.course = code and registrations.student = coursequeuepositions.student WHERE registrations.student=?;"
        );) {
            st.setString(1, student);
            ResultSet rs = st.executeQuery();
            while (rs.next()) {
				JSONObject arrObj = new JSONObject();
                arrObj.put("course", rs.getString(1));
                arrObj.put("code", rs.getString(2));
				String status = rs.getString(3);
                arrObj.put("status", status);
				if (status.equals("waiting")){
					arrObj.put("position",rs.getString(4));
				}
				obj.append("registered",arrObj);
            }
			rs.close();
        }
		
		

        return obj.toString();
    }

    // This is a hack to turn an SQLException into a JSON string error message. No need to change.
    public static String getError(SQLException e) {
        String message = e.getMessage();
        int ix = message.indexOf('\n');
        if (ix > 0) message = message.substring(0, ix);
        message = message.replace("\"", "\\\"");
        return message;
    }
}