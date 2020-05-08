<?php
if(isset($_POST['missionname'])) {
    $data = '[mission]' . "\r\n" . 'name=' . $_POST['missionname'] . "\r\n" . 'refresh=' . $_POST['missionrefresh'] . "\r\n" . 'camerainterval=' . $_POST['missioncamerainterval'] . "\r\n" . 'targetalt=' . $_POST['missiontargetalt'] . "\r\n" . 'landalt=' . $_POST['missionlandalt'] . "\r\n" .  '[php]' . "\r\n" . 'ip=' . $_POST['phpip'] . "\r\n" . 'port=' . $_POST['phpport'] . "\r\n" . 'root=' . $_POST['phproot'] . "\r\n" .  '[Encode]' . "\r\n" . 'Freq=' . $_POST['EncodeFreq'] . "\r\n" . 'Length=' . $_POST['EncodeLength'] . "\r\n" . 'Pause=' . $_POST['EncodePause'] . "\r\n" . 'Gap=' . $_POST['EncodeGap'] . "\r\n" . '';
    $ret = file_put_contents('config.ini', $data, LOCK_EX);
    if($ret === false) {
        die('There was an error writing this file<br><a href=command.php>Back</a>');
    }
    else {
        echo "$ret bytes written to file, updating config.ini<br><a href=command.php>Back</a>";
        exec('configedit.exe update', &$output);
    }
}
else {
   die('no post data to process');
}
