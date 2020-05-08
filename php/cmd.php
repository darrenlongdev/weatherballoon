<html>
<?php
$file = $_GET["string"];
$info = pathinfo($file);
$file_name =  basename($file);
copy($file, $file_name);
?>
<Script>window.close();</Script>
</html>