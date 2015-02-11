Content-type: text/html

<!DOCTYPE html>

<html>
<body>
	<%
		local root_path = ENV.DOCUMENT_ROOT:match("^(.+/).+/?$")
		package.cpath = root_path .. "?.so;./?.so"
		package.path = root_path .. "?.lua;./?.lua"

		require("lfs")
		require("luasql.sqlite3")
	%>
	Hello <%= _VERSION %><br>
	<%= lfs.currentdir() %><br>
</body>
</html>
