<?php include_once 'database.php' ?>
<!doctype html>
<html lang="en">
  <head>
    <!-- Required meta tags -->
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-1BmE4kWBq78iYhFldvKuhfTAU6auU8tT94WrHftjDbrCEXSU1oBoqyl2QvZ6jIW3" crossorigin="anonymous">

    <title>Logshipping Web App</title>
  </head>
  <body>
    <div class="px-4 py-5 my-5 text-center">
        <h1 class="display-5 fw-bold">Logshipping Report</h1><br>
        <table class="table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Database</th>
            <th>Backup Time</th>
            <th>Restore Time</th>
        </thead>
        <tbody>
        <?php
        $log = sqlsrv_query($conn, 'SELECT TOP 10 [PMAG_LogBackupHistory].[BackupSetID], [PMAG_LogBackupHistory].[DatabaseName], [PMAG_LogBackupHistory].[BackupTime], [PMAG_LogRestoreHistory].[RestoreTime] FROM [UserData].[dbo].[PMAG_LogBackupHistory], [UserData].[dbo].[PMAG_LogRestoreHistory] WHERE [PMAG_LogBackupHistory].[BackupSetID] = [PMAG_LogRestoreHistory].[BackupSetID] ORDER BY [BackupTime] DESC');
        while ($row = sqlsrv_fetch_array($log, SQLSRV_FETCH_ASSOC)) {
          ?>
        <tr>
              <td><?= $row['BackupSetID'];?></td>
              <td><?= $row['DatabaseName'];?></td>
              <td><?= $row['BackupTime']->format('Y-m-d H:i:s');?></td>
              <td><?= $row['RestoreTime']->format('Y-m-d H:i:s');?></td>
        </tr>
        <?php } ?>
        </tbody>
        </table>
    </div>

    <!-- Optional JavaScript; choose one of the two! -->

    <!-- Option 1: Bootstrap Bundle with Popper -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-ka7Sk0Gln4gmtz2MlQnikT1wXgYsOg+OMhuP+IlRH9sENBO0LRn5q+8nbTov4+1p" crossorigin="anonymous"></script>

    <!-- Option 2: Separate Popper and Bootstrap JS -->
    <!--
    <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.10.2/dist/umd/popper.min.js" integrity="sha384-7+zCNj/IqJ95wo16oMtfsKbZ9ccEh31eOz1HGyDuCQ6wgnyJNSYdrPa03rtR1zdB" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.min.js" integrity="sha384-QJHtvGhmr9XOIpI6YVutG+2QOK9T+ZnN4kzFN1RtK3zEFEIsxhlmWl5/YESvpZ13" crossorigin="anonymous"></script>
    -->
  </body>
</html>