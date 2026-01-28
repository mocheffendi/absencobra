
<?php
$id_pegawai=$_SESSION['id'];
?>

<div class="main-container container">
            <div class="row mb-3">
                <div class="col">
                    <h5 class="mb-0">Pengajuan Cuti/Izin</h5>
                </div>
            </div>
            <form class="needs-validation" action='include/modul.php?mod=cuti' method='POST'  enctype="multipart/form-data">
            <div class="row">
                <div class="col-12">
                    <div class="card card-light shadow-sm mb-0">
                        <div class="card-body">
                            <div class="row">
                            <div class="col align-self-center">
                                        <h5 class="mb-0">Rentang Cuti</h5>
                                        <input type="text" id="daterange" class="d-none calendar-daterange" name="tgl" required>
                                        <p class="textdate"></p>
                                    </div>
                                    <div class="col-auto">
                                        <a class="btn btn-sm btn-theme shadow-sm daterange-btn">
                                            <i class="bi bi-calendar-range size-22"></i>
                                        </a>
                                    </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="row">
                <div class="col-12">
                    <div class="card card-light shadow-sm mb-4">
                        <div class="card-body">
                            <!-- <div class="row"> -->
                                <div class="col-12 col-md-6 col-lg-4 mb-3">
                                    <div class="form-group form-floating">
                                    <select class="form-control" name="jenis" id="jenis" required>
                                            <option selected value="">pilih jenis cuti/izin..</option>
                                            <option value="1">Cuti Tahunan</option>
                                            <option value="2">Cuti Melahirkan</option>
                                            <option value="3">Sakit</option>
                                            <option value="4">Izin Karena Alasan Penting</option>
                                            <option value="5">Izin Berduka</option>
                                            <!-- <option value="3">Cuti diluar Tanggungan Negara</option> -->
                                        </select>
                                        <label class="form-control-label" for="address4">Jenis Cuti</label>
                                    </div>
                                </div>
                                <div class="col-12 col-md-6 col-lg-4 mb-3">
                                    <div class="form-group form-floating">
                                        <textarea type="text" id="satuan" rows="4" name="ket"  required class="form-control"></textarea>
                                        <label class="form-control-label" for="address2">Keterangan</label>
                                    </div>
                                </div>
                                <div class="col-12 col-md-6 col-lg-4">
                                    <div class="form-group form-floating ">
                                        <input type="file"  name="file2" class="form-control" id="fileupload" required>
                                        <label for="fileupload">Uplaod File surat cuti/izin</label>
                                    </div>
                                </div>
                                
                            <!-- </div> -->
                        </div>
                    </div>
                </div>
            </div>
            <div class="row h-100 mb-4">
                <div class="col-12 d-grid">
                            <button class="btn btn-lg btn-default shadow-sm" type="submit" >Simpan
                                <!-- <i class="mdi mdi-pencil right"></i> -->
                            </button>
                </div>
            </div>
            </form>
            <div class="row">
                <div class="col-12">
                    <div class="card shadow-sm mb-4 ">
                        <ul class="list-group list-group-flush bg-none">
                            <?php
                            // echo "select * from tb_cuti where id_pegawai='".$id_pegawai."' order by id_cuti desc";
                            $result = mysqli_query($mysqli, "select * from tb_cuti where id_pegawai='".$id_pegawai."' order by id_cuti desc limit 5");

							$no=1;
							while($user_data = mysqli_fetch_array($result)) {
                                $tgl_mulai=date('d/m/Y',strtotime($user_data['tgl']));
                                $tgl_sampai=date('d/m/Y',strtotime($user_data['tgl_sampai']));
                                
                                $jenis_cuti=$user_data['jenis_cuti'];
                                $ket=$user_data['ket'];
                                $st=$user_data['st'];
                                switch ($jenis_cuti){
                                    case "1":
                                        $jenis_cuti="Cuti Tahunan";
                                    break;
                                    case "2":
                                        $jenis_cuti="Cuti Melahirkan";
                                    break;
                                    case "3":
                                        $jenis_cuti="Sakit";
                                    break;
                                    case "4":
                                        $jenis_cuti="Izin Karena Alasan Penting";
                                    break;
                                    case "5":
                                        $jenis_cuti="Izin Berduka";
                                    break;
                                }
                                
                                if(is_null($st)){
                                    ?>
                                    <li class="list-group-item border-0">
                                        <div class="row">
                                            <div class="col-auto">
                                            <i class="avatar avatar-50 bi bi-question-circle fs-4 bg-primary-light text-primary rounded-circle mb-4"></i>
                                                <!-- <figure class="avatar avatar-50 rounded-circle">
                                                    <img src="assets/img/user1.jpg" alt="">
                                                </figure> -->
                                            </div>
                                            <div class="col px-0">
                                            <p><?php echo $jenis_cuti;?><br><small class="text-opac"><?php echo "Tgl cuti/izin ".$tgl_mulai." sd ".$tgl_sampai;?></small></p>   
                                            </div>
                                            <div class="col-auto text-end">
                                                <p>
                                                    <small class="text-opac">menunggu</small>
                                                </p>
                                            </div>
                                        </div>
                                    </li>
                                    <?php

                                }else{
                                    if($st == "1"){
                                        ?>
                                        <li class="list-group-item border-0">
                                            <div class="row">
                                                <div class="col-auto">
                                                <i class="avatar avatar-50 bi bi-check-circle fs-4 bg-primary-light text-color-theme rounded-circle mb-4"></i>
                                                    <!-- <figure class="avatar avatar-50 rounded-circle">
                                                        <img src="assets/img/user1.jpg" alt="">
                                                    </figure> -->
                                                </div>
                                                <div class="col px-0">
                                                <p><?php echo $jenis_cuti;?><br><small class="text-opac"><?php echo "Tgl cuti/izin ".$tgl_mulai." sd ".$tgl_sampai;?></small></p>
                                                </div>
                                                <div class="col-auto text-end">
                                                    <p>
                                                        <small class="text-opac">disetujui</small>
                                                    </p>
                                                </div>
                                            </div>
                                        </li>
                                        <?php
                                    }elseif($st == "0"){
                                        ?>
                                        <li class="list-group-item border-0">
                                            <div class="row">
                                                <div class="col-auto">
                                                <i class="avatar avatar-50 bi bi-exclamation-circle fs-4 bg-primary-light text-danger rounded-circle mb-4"></i>
                                                    <!-- <figure class="avatar avatar-50 rounded-circle">
                                                        <img src="assets/img/user1.jpg" alt="">
                                                    </figure> -->
                                                </div>
                                                <div class="col px-0">
                                                <p><?php echo $jenis_cuti;?><br><small class="text-opac"><?php echo "Tgl cuti/izin ".$tgl_mulai." sd ".$tgl_sampai;?></small></p>
                                                </div>
                                                <div class="col-auto text-end">
                                                    <p>
                                                        <small class="text-opac">ditolak</small>
                                                    </p>
                                                </div>
                                            </div>
                                        </li>
                                        <?php
                                    }
                                }
                            }
                            ?>
                        </ul>
                    </div>
                </div>
            </div>
            
</div>


<!-- =======================================================
=======================================================
======================================================= -->
