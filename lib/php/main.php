
<?php
error_reporting(1);
session_start();
//include "config/class_database.php";
include "include/config.php";
if (empty($_SESSION['username']) ){
	echo "<meta http-equiv='refresh' content='0; url=../index.php?code=21'>";
}

$strsqlx="select * from tb_aplikasi";
$result = mysqli_query($mysqli, $strsqlx);
$data = mysqli_fetch_array($result);
$nums = mysqli_num_rows($result);
if ($nums > 0 ){
    $titleapp=$data['nama_aplikasi'];
    $keterangan_aplikasi=$data['keterangan'];
    $faveicon=$data['faveicon'];
    $logo_aplikasi=$data['logo_aplikasi'];
}
?>
<!doctype html>
<html lang="en" class="light-mode">



<?php
include "include/header.php";

?>

<body class="body-scroll"  data-page="stats">

    <!-- loader section -->
    <div class="container-fluid loader-wrap">
        <div class="row h-100">
            <div class="col-10 col-md-6 col-lg-5 col-xl-3 mx-auto text-center align-self-center">
                <div class="loader-cube-wrap mx-auto">
                    <div class="loader-cube1 loader-cube"></div>
                    <div class="loader-cube2 loader-cube"></div>
                    <div class="loader-cube4 loader-cube"></div>
                    <div class="loader-cube3 loader-cube"></div>
                </div>
                <p>Let's Create Difference<br><strong>Please wait...</strong></p>
            </div>
        </div>
    </div>
    <!-- loader section ends -->

    <!-- Sidebar main menu -->
    <?php
    include "include/sidemenu.php";
    ?>
    <!-- Sidebar main menu ends -->

    <!-- Begin page -->
    <main class="h-100 has-header has-footer">

        <!-- Header -->
        <?php
        include "include/title.php";
        include "include/fill.php";
        ?>
        <!-- Header ends -->
        
        <!-- main page content -->
        
        <!-- main page content ends -->

        
    </main>
    <!-- Page ends-->

    <!-- Footer -->
    <footer class="footer">
        <div class="container">
            <ul class="nav nav-pills nav-justified">
                <li class="nav-item">
                    <a class="nav-link active" href="?mod=dashboard">
                        <span>
                            <i class="nav-icon bi bi-house"></i>
                            <span class="nav-text">Home</span>
                        </span>
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="?mod=kinerja">
                        <span>
                            <i class="nav-icon bi bi-camera"></i>
                            <span class="nav-text">Absen</span>
                        </span>
                    </a>
                </li>
                <li class="nav-item center-item">
                    <a class="nav-link" href="?mod=menuall">
                        <span>
                            <i class="nav-icon bi bi-filter"></i>
                            <span class="nav-text">Menu</span>
                        </span>
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="?mod=cuti">
                        <span>
                            <i class="nav-icon bi bi-box-seam"></i>
                            <span class="nav-text">Kepegawaian</span>
                        </span>
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="?mod=lp">
                        <span>
                            <i class="nav-icon bi bi-file-earmark-text"></i>
                            <span class="nav-text">Laporan</span>
                        </span>
                    </a>
                </li>
            </ul>
        </div>
    </footer>
    <!-- Footer ends-->

    <!-- filter menu -->
    
    <!-- filter menu ends-->

    <!-- event action toast messages -->
    
    <!-- event action toast messages -->
    <div class="position-fixed top-0 start-50 translate-middle-x p-3  z-index-999">
        <div id="toastprouctaddedtiny1" class="toast bg-primary border-0 shadow hide mb-3" role="alert" aria-live="assertive"
            aria-atomic="true">
            <div class="toast-body">
                <div class="row">
                    <div class="col text-white">
                        <p>Data Berhasil Disimpan</p>
                    </div>
                    <div class="col-auto">
                        <button type="button" class="btn-close" data-bs-dismiss="toast" aria-label="Close"></button>
                    </div>
                </div>
            </div>
        </div>
        <div id="toastprouctaddedtiny2" class="toast bg-danger border-0 shadow hide mb-3" role="alert" aria-live="assertive"
            aria-atomic="true">
            <div class="toast-body">
                <div class="row">
                    <div class="col text-white">
                        <p>Data Gagal Disimpan</p>
                    </div>
                    <div class="col-auto">
                        <button type="button" class="btn-close" data-bs-dismiss="toast" aria-label="Close"></button>
                    </div>
                </div>
            </div>
        </div>

    </div>
    <!-- event action toast messages ends -->
    <!-- event action toast messages ends -->

    <!-- add cart modal -->
    
    <!-- add cart modal ends -->

    <!-- PWA app install toast message -->
    <!-- <div class="position-fixed bottom-0 start-50 translate-middle-x  z-index-9">
        <div class="toast mb-3" role="alert" aria-live="assertive" aria-atomic="true" id="toastinstall"
            data-bs-animation="true">
            <div class="toast-header">
                <img src="assets/img/favicon32.png" class="rounded me-2" alt="...">
                <strong class="me-auto">Install PWA App</strong>
                <small>now</small>
                <button type="button" class="btn-close" data-bs-dismiss="toast" aria-label="Close"></button>
            </div>
            <div class="toast-body">
                <div class="row">
                    <div class="col">
                        Click "Install" to install PWA app and experience as indepedent app.
                    </div>
                    <div class="col-auto align-self-center">
                        <button class="btn-default btn btn-sm" id="addtohome">Install</button>
                    </div>
                </div>
            </div>
        </div>
    </div> -->



 

  

     <script src="assets/js/jquery-3.3.1.min.js"></script>
    <script src="assets/js/popper.min.js"></script>
    <script src="assets/vendor/bootstrap-5/js/bootstrap.bundle.min.js"></script>
    <script src="assets/js/jquery.cookie.js"></script>
    <script src="assets/js/pwa-services.js"></script>
    <script src="assets/vendor/swiperjs-6.6.2/swiper-bundle.min.js"></script>
    <script src="assets/vendor/nouislider/nouislider.min.js"></script>
    <script src="assets/vendor/chart-js-3.3.1/chart.min.js"></script>
    <script src="assets/vendor/fullcalendar-5.7/main.js"></script>
    <script src="assets/vendor/progressbar-js/progressbar.min.js"></script>
    <script src="https://cdn.jsdelivr.net/momentjs/latest/moment.min.js"></script>
    <script src="assets/vendor/daterangepicker/daterangepicker.js"></script>
    <script src="assets/js/main.js"></script>
    <script src="assets/js/color-scheme.js"></script>
    <script src="assets/js/app.js"></script>


    <?php
    include "include/footer.php";
    ?>
</body>

</html>