# Custom Logshipping dengan SQL Server (Windows)

Proyek ini bertujuan melakukan logshipping custom yang terotomasi.

Proyek ini mengambil referensi utama dari sumber [berikut](https://sqlperformance.com/2014/10/sql-performance/readable-secondaries-on-a-budget).

## Requirement

* 2 instance SQL SERVER

  Satu instance akan digunakan sebagai server primary sementara satu lagi akan digunakan sebagai server secondary.
  
  Instance yang digunakan dalam proyek ini yaitu ```NARENDRA\NARENDRA``` sebagai primary dan ```NARENDRA\NARENDRASCND``` sebagai secondary
* Windows Task Scheduler

  Task scheduler akan digunakan untuk melakukan otomasi log backup.
* SQLCMD

  Sebagai script yang digunakan dalam Task scheduler.
  
## Instalasi Logshipping

Instalasi aplikasi dilakukan dengan mengaktifkan koneksi kedua instance dan menjalankan file query secara berurutan yang ada pada folder ```/logshipping_query```

#### 0. Create DB

Query ini akan membuat database dengan nama ```logshipped```

#### 1. Add linked server

Membuat koneksi dengan server secondari yaitu ```NARENDRA\NARENDRASCND```.

#### 2. Create table

Membuat tabel pada database ```logshipped```

Tabel yang dibuat yaitu:

* ```PMAG_Databases```

Tabel ini akan digunakan untuk menyimpan nama database yang akan dibackup

* ```PMAG_Secondaries```

Tabel ini akan digunakan untuk menyimpan informasi server secondary tempat akan dilakukan restore

* ```PMAG_LogBackupHistory```

Tabel ini akan menyimpan riwayat backup yang telah dilakukan

* ```PMAG_LogRestoreHistory```

Tabel ini akan menyimpan riwayat restore yang telah dilakukan

#### 3. PMAG_Backup SP

Membuat stored procedure yang akan dipanggil untuk melakukan backup dan restore. Stored procedure ini juga memanggil stored procedure ```PMAG_InitializeSecondaries``` dan ```PMAG_RestoreLogs``` ketika dijalankan.

#### 4. PMAG_InitializeSecondaries SP

Stored procedure ini menginisialisasi server secondary yang digunakan ketika backup dilakukan. Stored procedure ini juga memanggil stored procedure ```PMAG_Backup``` dan ```PMAG_RestoreLogs``` ketika dijalankan.

#### 5. PMAG_RestoreLogs SP

Stored procedure ini akan menjalankan proses restore setelah backup dilakukan.

#### 6. PMAG_CleanupHistory SP

Stored procedure ini akan digunakan untuk menghapus riwayat backup restore yang telah dilakukan.

#### 7. Insert table

Melakukan query insert ke table ```PMAG_Databases``` untuk mendefinisikan database yang akan dibackup dan restore, selain itu juga ke table ```PMAG_Secondaries``` untuk mendefinisikan server secondary yang akan digunakan.

#### 8. Full backup

Menjalankan stored procedure ```PMAG_Backup``` dengan type **bak** yaitu melakukan backup database secara keseluruhan

#### 9. Log backup

Menjalankan stored procedure ```PMAG_Backup``` dengan type **trn** yaitu melakukan backup berdasarkan kondisi/perubahan yang terjadi pada database

## Konfigurasi Otomasi Logshipping

Otomasi diperlukan untuk menjalankan ```PMAG_Backup``` dengan type **trn** setiap 30 menit. Pembuatan otomasi dilakukan dengan task scheduler.

#### 1. Buat basic task

Buka task scheduler pada windows dan buat **Basic task**. Beri nama dan deskripsi task.

![Create basic task](https://raw.githubusercontent.com/bayunarendrajati/custom_logshipping/master/img/1.jpg)

#### 2. Atur trigger dan action

Atur trigger menjadi **daily** pada jam yang diinginkan.

Atur action menjadi **start a program** dan berikan script ```logshipping.bat``` pada field **Program/script**

![Trigger and action conf](https://raw.githubusercontent.com/bayunarendrajati/custom_logshipping/master/img/2.jpg)

#### 3. Klik **Next** dan **Finish**

#### 4. Mengatur task properties

Pada tab ```General``` atur permission menjadi **Run whether user is logged in or not** dan **Run with highest privileges**. Atur konfiguras versi OS jika diperlukan.

![General conf](https://raw.githubusercontent.com/bayunarendrajati/custom_logshipping/master/img/3.jpg)

Pada tab ```Triggers``` edit trigger yang sudah ada dan dan atur **Repeat task every:** menjadi 30 menit

![General conf](https://raw.githubusercontent.com/bayunarendrajati/custom_logshipping/master/img/4.jpg)

Pada tab ```Conditions``` uncheck **Start the task only if the computer is on AC power**, jika sudah klik **Ok**

![General conf](https://raw.githubusercontent.com/bayunarendrajati/custom_logshipping/master/img/5.jpg)

#### 5. Run task
