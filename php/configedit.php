<html>
<head>
<title>Command | Flight Management System</title>
<link rel="icon" href="icon_svg.svg">
<link rel="stylesheet" id="all-css" href="style.css" type="text/css" media="all">
</head>
<body>
	<div id="wrapper">
		<div id="header">
			<div id="title">Flight Management System</div><!--end title-->
			<div id="description">
				<h2>PHP Server Graphical User Interface</h2>
			</div><!--end description-->
			<div id="nav">
				<ul class="menu">
				<li id="menu-item-1" class="menu-item"><a href="index.php">Data</a></li>
				<li id="menu-item-2" class="menu-item"><a href="images.php">Images</a></li>
				<li id="menu-item-3" class="menu-item"><a href="services.php">Services</a></li>
				<li id="menu-item-4" class="menu-item current-menu-item"><a href="command.php">Command</a></li>
				</ul>
			</div><!--end nav-->
		</div><!--end header-->
		<div id="fullwidthcontent" class="fullwidthcontent">
			<br>
			<h2>Config Editor</h2><br>

<?php
exec('configedit.exe read', &$output);
echo file_get_contents("config.html")
?>

		</div><!--end fullwidthcontent-->
	<div id="footer"><p class="right"><small>Unmanned flight computer written by Darren Long based on NASA opensource FMS</small></p></div><!--end footer-->
</div><!--end wrapper-->
</body>
</html>