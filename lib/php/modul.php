<?php
error_reporting(1);
session_start();
include "config.php";
if (isset($_SESSION['username']) && !empty($_SESSION['username'])){
	$seksi=$_SESSION['seksi'];
	$cabang=$_SESSION['cabang'];
	$kode_jam=$_SESSION['kode_jam'];
	$username=$_SESSION['username'];
	$idpegawai=$_SESSION['id'];
if($_GET['mod'] == 'password'){
$pwdbaru=$_POST['pwd2'];
$pwdlama=$_POST['pwd1'];
//$pwdbaru = antiSQLinject($pwdbaru);
$pwdbaru=md5($pwdbaru);
//$pwdlama = antiSQLinject($pwdlama);
$pwdlama=md5($pwdlama);

	// if ($_POST['pwd2'] != $_POST['pwd3']){
	// 	header("Location: ../main.php?mod=password&code=2");
	// } else {
	// $result = mysqli_query($mysqli, "select * from tb_pegawai where username='$username' and psw='$pwdlama'");
	// $data = mysqli_fetch_array($result);
	// $nums = mysqli_num_rows($result);
	// 	if ($nums > 0 ){
	// 		$result = mysqli_query($mysqli, "update tb_pegawai set psw='$pwdbaru'  where username='$username'");
	// 		if ($result){
	// 			header("Location: ../main.php?mod=password&code=1");
	// 		}else{
	// 			header("Location: ../main.php?mod=password&code=2");
	// 		}
	// 	} else {
	// 		header("Location: ../main.php?mod=password&code=2");
	// 	}
	// }
	if ($_POST['pwd2'] != $_POST['pwd3']){
		header("Location: ../main.php?mod=profile&code=2");
	} else {
	$result = mysqli_query($mysqli, "select * from tb_pegawai where username='$username' and psw='$pwdlama'");
	$data = mysqli_fetch_array($result);
	$nums = mysqli_num_rows($result);
		if ($nums > 0 ){
			$result = mysqli_query($mysqli, "update tb_pegawai set psw='$pwdbaru'  where username='$username'");
			if ($result){
				header("Location: ../main.php?mod=profile&code=1");
			}else{
				header("Location: ../main.php?mod=profile&code=2");
			}
		} else {
			header("Location: ../main.php?mod=profile&code=2");
		}
	}
} elseif($_GET['mod'] == 'absenmasuk'){
	$username=$_POST['username'];
	$id_pegawai=$_POST['id_pegawai'];
	$cabang=$_POST['cabang'];
	$id_jam=$_POST['id_jam'];
	$seksi=$_POST['seksi'];
	$latitudeFrom=$_POST['nilLT'];
	$longitudeFrom=$_POST['nilLG'];
	$tmpt=$_POST['tmpt'];
	$harimasuk=date('Y-m-d H:i:s');
	$namatgl=date('YmdHi');
	$sekarang=date('Y-m-d');
	$file= $_FILES['file2']['name'];
	$file_ext= strtolower(end(explode('.', $file)));
	$fileName=$id_pegawai.$namatgl.".".$file_ext;

	$result = mysqli_query($mysqli, "select  * from tb_tmpt where id_cabang='$cabang' and id_tmpt='$tmpt' order by id_tmpt ");
	$no=1;
	while($user_data = mysqli_fetch_array($result)) {   
		$latitudeTo=$user_data['latitude'];
		$longitudeTo=$user_data['longitude'];
	}
	// $range=haversineGreatCircleDistance($latitudeFrom, $longitudeFrom, $latitudeTo, $longitudeTo, $earthRadius = 6371000);
	// if($range <= 1000)
	// {
		if(!empty($username) && isset($username)){
			$jammasuk=date('H:i:s');
			$resultr = mysqli_query($mysqli, "select * from tb_pegawai where  id_cabang='$cabang' and id_pegawai = '$id_pegawai'");
			$datar = mysqli_fetch_array($resultr);
			$numsr = mysqli_num_rows($resultr);
			if ($numsr > 0 ){
				$kode_jam=$datar['kode_jam'];
			}
			$resulty = mysqli_query($mysqli, "select nama_libur from tb_libur  where date_format(tgl_libur,'%Y-%m-%d') = '$sekarang' and  id_cabang='$cabang' and id_seksi = '$seksi'");
			$datay = mysqli_fetch_array($resulty);
			$numsy = mysqli_num_rows($resulty);
			if ($numsy > 0 ){
				$nama_libur=$datay['nama_libur'];			
				$result = mysqli_query($mysqli, "insert into tb_absen (id_pegawai,username,latitude,longitude,class,jam_masuk,harimasuk,wktmasuk,id_cabang,keterangan,foto) values ('$id_pegawai','$username','$latitudeFrom','$longitudeFrom','event-info','$jammasuk','$harimasuk','$jammasuk','$cabang','lembur kerja','$fileName')");
				move_uploaded_file($_FILES['file2']['tmp_name'], "../assets/img/absen/".$fileName);
				// $result = mysqli_query($mysqli, "insert into tb_absen (username,latitude,longitude,class,jam_masuk,harimasuk,wktmasuk,id_cabang,keterangan,foto) values ('$username','$latitudeFrom','$longitudeFrom','event-info','$jammasuk','$harimasuk','$jammasuk','$cabang','lembur kerja','$fileName')");
				// move_uploaded_file($_FILES['file2']['tmp_name'], "../assets/img/absen/".$fileName);
				if ($result){
					$hasil='1';
				}else{
					$hasil='2';
				}
			} else {
				$resultf = mysqli_query($mysqli, "select * from tb_absen where  id_cabang='$cabang' and id_pegawai = '$id_pegawai' and date_format(harimasuk,'%Y-%m-%d') = '$sekarang'");
				$dataf = mysqli_fetch_array($resultf);
				$numsf = mysqli_num_rows($resultf);
				if ($numsf > 0 ){
					$hasil='2';
				} else{
					$harisekarang=hari_indo($sekarang, true);
					$resultv = mysqli_query($mysqli, "select j.jam_in, j.jam_out from tb_jam j where  j.id_cabang='$cabang' and j.id_jam='$id_jam'");
					// $resultv = mysqli_query($mysqli, "select j.jam_in, j.jam_out from tb_jam j where  j.id_cabang='$cabang' and j.id_jam='$kode_jam'");	==========CATATAN==========
					$isian="select j.jam_in, j.jam_out from tb_jam j where  j.id_cabang='$cabang' and j.id_jam='$kode_jam'";
					$datav = mysqli_fetch_array($resultv);
					$numsv = mysqli_num_rows($resultv);
					if ($numsv > 0 ){ 
						$jam_masuk=$datav['jam_in'];
						$jam_keluar=$datav['jam_out'];
						$hitung_terlambat=strtotime($jammasuk) -  strtotime($jam_masuk);
						$jam   = floor($hitung_terlambat / (60 * 60));
						$menit = $hitung_terlambat - $jam * (60 * 60);
						if($hitung_terlambat > 0){
							$terlambat= $jam.':'.floor($menit/60);
						}else{
							$terlambat="00:00:00";
						}
						$result = mysqli_query($mysqli, "insert into tb_absen (id_pegawai,username,latitude,longitude,class,jam_masuk,jam_keluar,harimasuk,wktmasuk,id_cabang,dtg_terlambat,foto) values ('$id_pegawai','$username','$latitudeFrom','$longitudeFrom','event-info','$jam_masuk','$jam_keluar','$harimasuk','$jammasuk','$cabang','$terlambat','$fileName')");
						move_uploaded_file($_FILES['file2']['tmp_name'], "../assets/img/absen/".$fileName);
						// $result = mysqli_query($mysqli, "insert into tb_absen (username,latitude,longitude,class,jam_masuk,jam_keluar,harimasuk,wktmasuk,id_cabang,dtg_terlambat,foto) values ('$username','$latitudeFrom','$longitudeFrom','event-info','$jam_masuk','$jam_keluar','$harimasuk','$jammasuk','$cabang','$terlambat','$fileName')");
						// move_uploaded_file($_FILES['file2']['tmp_name'], "../assets/img/absen/".$fileName);
						if ($result){
							$hasil='1';
						}else{
							$hasil='2';
						}
					} else {
						$jammasuk=date('H:i:s');
						$result = mysqli_query($mysqli, "insert into tb_absen (id_pegawai,username,latitude,longitude,class,jam_masuk,harimasuk,wktmasuk,id_cabang,keterangan,foto) values ('$id_pegawai','$username','$latitudeFrom','$longitudeFrom','event-info','$jammasuk','$harimasuk','$jammasuk','$cabang','lembur kerja','$fileName')");
						move_uploaded_file($_FILES['file2']['tmp_name'], "../assets/img/absen/".$fileName);
						// $result = mysqli_query($mysqli, "insert into tb_absen (username,latitude,longitude,class,jam_masuk,harimasuk,wktmasuk,id_cabang,keterangan,foto) values ('$username','$latitudeFrom','$longitudeFrom','event-info','$jammasuk','$harimasuk','$jammasuk','$cabang','lembur kerja','$fileName')");
						// move_uploaded_file($_FILES['file2']['tmp_name'], "../assets/img/absen/".$fileName);
						if ($result){
							$hasil='1';
						}else{
							$hasil='2';
						}
					}
	
	
				}
				
				
			}
		
		
			
		} else {
			$hasil='3';
		}
		
		if ($hasil == '1'){
					header("Location: ../main.php?mod=absen_masuk&code=1");
				}elseif ($hasil == '2'){
					header("Location: ../main.php?mod=absen_masuk&code=2");
				} else {
					header("Location: ../main.php?mod=absen_masuk&code=3");
			  }
	// }else{
	// 	header("Location: ../main.php?mod=absen_masuk&code=4");
	// }
	?>
	<script>
		alert(<?php echo $hasil;?>);
	</script>
	<?php
	
	//die(json_encode(array('items'=>$hasil)));
} elseif($_GET['mod'] == 'absenkeluar'){
	
	$username=$_POST['username'];
	$id_pegawai=$_POST['id_pegawai'];
	$cabang=$_POST['cabang'];
	$harikeluar=date('Y-m-d H:i:s');
	$wktkeluar=date('H:i:s');
	$sekarang=date('Y-m-d');

	$seksi=$_POST['seksi'];
	$latitudeFrom=$_POST['nilLT'];
	$longitudeFrom=$_POST['nilLG'];
	$tmpt=$_POST['tmpt'];
	$namatgl=date('YmdHi');
	$sekarang=date('Y-m-d');
	$file= $_FILES['file2']['name'];
	$file_ext= strtolower(end(explode('.', $file)));
	$fileName="k".$id_pegawai.$namatgl.".".$file_ext;
	
	$result = mysqli_query($mysqli, "select  * from tb_tmpt where id_cabang='$cabang' and id_tmpt='$tmpt' order by id_tmpt ");
	$no=1;
	while($user_data = mysqli_fetch_array($result)) {   
		$latitudeTo=$user_data['latitude'];
		$longitudeTo=$user_data['longitude'];
	}
	// $range=haversineGreatCircleDistance($latitudeFrom, $longitudeFrom, $latitudeTo, $longitudeTo, $earthRadius = 6371000);
	// if($range <= 1000)
	// {

	if(!empty($username) && isset($username)){
		$resultv = mysqli_query($mysqli, "select * from tb_absen where harimasuk like '$sekarang%' and id_pegawai='$id_pegawai' and id_cabang='$cabang'");
		$datav = mysqli_fetch_array($resultv);
		$numsv = mysqli_num_rows($resultv);
		if ($numsv > 0 ){ 
			$jam_keluar=$datav['jam_keluar'];
			$wktmasuk=$datav['wktmasuk'];
		}
		if ($jam_keluar == '00:00:00'){
			$pulang_awal=strtotime($wktkeluar) -  strtotime($wktkeluar);
			$jam   = floor($pulang_awal / (60 * 60));
			$menit = $pulang_awal - $jam * (60 * 60);
			$pulang_awal= '00:00:00'	; //$jam.':'.floor($menit/60);
			
			$durasi=strtotime($wktkeluar) -  strtotime($wktmasuk);
			$jam   = floor($durasi / (60 * 60));
			$menit = $durasi - $jam * (60 * 60);
			$durasi= $jam.':'.floor($menit/60);
			
			$result = mysqli_query($mysqli, "update tb_absen set harikeluar='$harikeluar',fotok='$fileName', jam_keluar='$wktkeluar', pulang_awal='$pulang_awal', wktkeluar='$wktkeluar', durasi='$durasi', latitudek='$latitudeFrom', longitudek='$longitudeFrom' where id_cabang='$cabang' and id_pegawai='$id_pegawai' and date_format(harimasuk,'%Y-%m-%d') = '$sekarang' and harikeluar is null");
			$printr= "update tb_absen set harikeluar='$harikeluar', jam_keluar='$wktkeluar', pulang_awal='$pulang_awal', wktkeluar='$wktkeluar', durasi='$durasi', latitudek='$latitudeFrom', longitudek='$longitudeFrom' where id_cabang='$cabang' and username='$username' and date_format(harimasuk,'%Y-%m-%d') = '$sekarang' and harikeluar is null";
			// $result = mysqli_query($mysqli, "update tb_absen set harikeluar='$harikeluar', jam_keluar='$wktkeluar', pulang_awal='$pulang_awal', wktkeluar='$wktkeluar', durasi='$durasi', latitudek='$latitudeFrom', longitudek='$longitudeFrom', fotok='$fileName' where id_cabang='$cabang' and username='$username' and date_format(harimasuk,'%Y-%m-%d') = '$sekarang' and harikeluar is null");
			// $printr= "update tb_absen set harikeluar='$harikeluar', jam_keluar='$wktkeluar', pulang_awal='$pulang_awal', wktkeluar='$wktkeluar', durasi='$durasi', latitudek='$latitudeFrom', longitudek='$longitudeFrom', fotok='$fileName' where id_cabang='$cabang' and username='$username' and date_format(harimasuk,'%Y-%m-%d') = '$sekarang' and harikeluar is null";
			if ($result){
				move_uploaded_file($_FILES['file2']['tmp_name'], "../assets/img/absen/".$fileName);
				$hasil='1';
			}else{
				$hasil='2';
			}
		} elseif(strtotime($jam_keluar) >  strtotime($wktkeluar)) {
			$pulang_awal=strtotime($jam_keluar) -  strtotime($wktkeluar);
			$jam   = floor($pulang_awal / (60 * 60));
			$menit = $pulang_awal - $jam * (60 * 60);
			$pulang_awal= $jam.':'.floor($menit/60);
			
			$durasi=strtotime($wktkeluar) -  strtotime($wktmasuk);
			$jam   = floor($durasi / (60 * 60));
			$menit = $durasi - $jam * (60 * 60);
			$durasi= $jam.':'.floor($menit/60);
			$result = mysqli_query($mysqli, "update tb_absen set harikeluar='$harikeluar', pulang_awal='$pulang_awal',fotok='$fileName', wktkeluar='$wktkeluar', durasi='$durasi', latitudek='$latitudeFrom', longitudek='$longitudeFrom' where id_cabang='$cabang' and id_pegawai='$id_pegawai' and date_format(harimasuk,'%Y-%m-%d') = '$sekarang' and harikeluar is null");
			$printr= "update tb_absen set harikeluar='$harikeluar', pulang_awal='$pulang_awal', wktkeluar='$wktkeluar', durasi='$durasi', latitudek='$latitudeFrom', longitudek='$longitudeFrom' where id_cabang='$cabang' and username='$username' and date_format(harimasuk,'%Y-%m-%d') = '$sekarang' and harikeluar is null";
			// $result = mysqli_query($mysqli, "update tb_absen set harikeluar='$harikeluar', pulang_awal='$pulang_awal', wktkeluar='$wktkeluar', durasi='$durasi', latitudek='$latitudeFrom', longitudek='$longitudeFrom', fotok='$fileName' where id_cabang='$cabang' and username='$username' and date_format(harimasuk,'%Y-%m-%d') = '$sekarang' and harikeluar is null");
			// $printr= "update tb_absen set harikeluar='$harikeluar', pulang_awal='$pulang_awal', wktkeluar='$wktkeluar', durasi='$durasi', latitudek='$latitudeFrom', longitudek='$longitudeFrom', fotok='$fileName' where id_cabang='$cabang' and username='$username' and date_format(harimasuk,'%Y-%m-%d') = '$sekarang' and harikeluar is null";
			if ($result){
				move_uploaded_file($_FILES['file2']['tmp_name'], "../assets/img/absen/".$fileName);
				$hasil='1';
			}else{
				$hasil='3';
			}
		
		} else {
			$pulang_awal= '00:00:00'	; //$jam.':'.floor($menit/60);
			$durasi=strtotime($wktkeluar) -  strtotime($wktmasuk);
			$jam   = floor($durasi / (60 * 60));
			$menit = $durasi - $jam * (60 * 60);
			$durasi= $jam.':'.floor($menit/60);
			$result = mysqli_query($mysqli, "update tb_absen set harikeluar='$harikeluar', pulang_awal='$pulang_awal',fotok='$fileName', wktkeluar='$wktkeluar', durasi='$durasi', latitudek='$latitudeFrom', longitudek='$longitudeFrom' where id_cabang='$cabang' and id_pegawai='$id_pegawai' and date_format(harimasuk,'%Y-%m-%d') = '$sekarang' and harikeluar is null");
			$printr="update tb_absen set harikeluar='$harikeluar', pulang_awal='$pulang_awal', wktkeluar='$wktkeluar', durasi='$durasi', latitudek='$latitudeFrom', longitudek='$longitudeFrom' where id_cabang='$cabang' and username='$username' and date_format(harimasuk,'%Y-%m-%d') = '$sekarang' and harikeluar is null";
			// $result = mysqli_query($mysqli, "update tb_absen set harikeluar='$harikeluar', pulang_awal='$pulang_awal', wktkeluar='$wktkeluar', durasi='$durasi', latitudek='$latitudeFrom', longitudek='$longitudeFrom', fotok='$fileName' where id_cabang='$cabang' and username='$username' and date_format(harimasuk,'%Y-%m-%d') = '$sekarang' and harikeluar is null");
			// $printr="update tb_absen set harikeluar='$harikeluar', pulang_awal='$pulang_awal', wktkeluar='$wktkeluar', durasi='$durasi', latitudek='$latitudeFrom', longitudek='$longitudeFrom', fotok='$fileName' where id_cabang='$cabang' and username='$username' and date_format(harimasuk,'%Y-%m-%d') = '$sekarang' and harikeluar is null";
			
			if ($result){
				move_uploaded_file($_FILES['file2']['tmp_name'], "../assets/img/absen/".$fileName);
				$hasil='1';
			}else{
				$hasil='4';
			}
		

		}
		
	} else {
		$hasil='2';
	}	
	// $tos="update tb_absen set harikeluar='$harikeluar', wktkeluar='$wktkeluar' where id_cabang='$cabang' and username='$username' and date_format(harimasuk,'%Y-%m-%d') = '$sekarang' and harikeluar = null";
	if ($hasil == '1'){
				header("Location: ../main.php?mod=absen_keluar&code=1");
			}elseif ($hasil == '2'){
				header("Location: ../main.php?mod=absen_keluar&code=2$printr");
			} elseif ($hasil == '3') {
				header("Location: ../main.php?mod=absen_keluar&code=3$printr");
			}else {
				header("Location: ../main.php?mod=absen_keluar&code=3$printr");
			}
		// }
		// else{
		// 	header("Location: ../main.php?mod=absen_keluar&code=4");
		// }
	//die(json_encode(array('items'=>$hasil)));
} elseif($_GET['mod'] == 'dinasluar'){


	$tos="insert into tb_dinasluar (id_pegawai,tgl,tgl_sampai,jenis_dinasluar,lampiran,ket,id_cabang ) values ('$idpegawai','$tgl','$jenis','$fileName','$ket','$cabang')";
		if (isset($_POST['tgl']) && isset($_POST['jenis'])){		
			$tgl=date('Y-m-d',strtotime($_POST['tgl']));
			$tgl_sampai=date('Y-m-d',strtotime($_POST['tgl_sampai']));
			$jenis=$_POST['jenis'];
			$file= $_FILES['file2']['name'];
			$file_ext= strtolower(end(explode('.', $file)));
			$ket=$_POST['ket'];
			$namatgl=date('Ymd',strtotime($tgl));
			//$tgl=date($tgl,'Y-m-d');
			
			$fileName=$idpegawai.$namatgl.".".$file_ext;
			
			
			
			if (isset($file)){
				$result = mysqli_query($mysqli, "insert into tb_dinasluar (id_pegawai,tgl,tgl_sampai,jenis_dinasluar,lampiran,ket,id_cabang ) values ('$idpegawai','$tgl','$tgl_sampai','$jenis','$fileName','$ket','$cabang')");
				if ($result){
					move_uploaded_file($_FILES['file2']['tmp_name'], "../assets/img/filedinasluar/".$fileName);
					$hasil='1';
				}else{
					$hasil='2';
				}
			}else{
				$hasil='2';
			}
			
		} else {
			$hasil='3';
		}
		if ($hasil == '1'){
					header("Location: ../main.php?mod=dinasluar&code=1");
				}elseif ($hasil == '2'){
					header("Location: ../main.php?mod=dinasluar&code=2");
				} else {
					header("Location: ../main.php?mod=dinasluar&code=2");
				}
				
	} elseif($_GET['mod'] == 'cuti'){
		$harimasuk=date('Y-m-d H:i:s');


	$tos="insert into tb_cuti (id_pegawai,tgl,tgl_sampai,jenis_cuti,lampiran,ket,id_cabang ) values ('$idpegawai','$tgl','$jenis','$fileName','$ket','$cabang')";
	if (isset($_POST['tgl']) && isset($_POST['jenis'])){		
		$tgl=$_POST['tgl'];
		$rentang=explode('-', $tgl);
		$tgl1=$rentang[0];
		$tgl2=$rentang[1];
		$tgl1=date('Y-m-d',strtotime($tgl1));
		$tgl2=date('Y-m-d',strtotime($tgl2));
		$jenis=$_POST['jenis'];
		$file= $_FILES['file2']['name'];
		$file_ext= strtolower(end(explode('.', $file)));
		$ket=$_POST['ket'];
		$namatgl=date('Ymd',strtotime($tgl));
		//$tgl=date($tgl,'Y-m-d');
		
		$fileName=$idpegawai.$namatgl.".".$file_ext;
		
		
		
		if (isset($file)){
			$result = mysqli_query($mysqli, "insert into tb_cuti (id_pegawai,tgl,tgl_sampai,jenis_cuti,lampiran,ket,id_cabang ) values ('$idpegawai','$tgl1','$tgl2','$jenis','$fileName','$ket','$cabang')");
			if ($result){
				move_uploaded_file($_FILES['file2']['tmp_name'], "../assets/img/filecuti/".$fileName);
				$hasil='1';
			}else{
				$hasil='2';
			}
		}else{
			$hasil='2';
		}
		
	} else {
		$hasil='3';
	}
	if ($hasil == '1'){
				header("Location: ../main.php?mod=cuti&code=1");
			}elseif ($hasil == '2'){
				header("Location: ../main.php?mod=cuti&code=2");
			} else {
				header("Location: ../main.php?mod=cuti&code=2");
			}
			
}  elseif($_GET['mod'] == 'kinerja'){

//echo $jam=$_POST['jam'];

	// if (isset($_POST['jam']) && isset($_POST['uraian']) && isset($_POST['vol'])){		
	if ( isset($_POST['uraian'])){		
		$jam= date('H:i:s'); //$_POST['jam'];
		$tgl=date('Y-m-d');
		$uraian=$_POST['uraian'];
		$file= $_FILES['file2']['name'];
		$file_ext= strtolower(end(explode('.', $file)));
		$namatgl=date('ymd',strtotime($tgl));
		$namajam=date('Hms',strtotime($jam));
		$fileName=$idpegawai.$namatgl.$namajam."1.".$file_ext;



		
		$file3= $_FILES['file3']['name'];
		$file_ext3= strtolower(end(explode('.', $file3)));
		$namatgl3=date('ymd',strtotime($tgl));
		$namajam3=date('Hms',strtotime($jam));
		$fileName3=$idpegawai.$namatgl3.$namajam3."2.".$file_ext3;




			
				$result = mysqli_query($mysqli, "insert into tb_kinerja (`id_pegawai`,`tgl`,`jam`,`uraian`,`before`,`after`,`id_cabang`) values ('$idpegawai','$tgl','$jam','$uraian','$fileName','$fileName3','$cabang')");
				// $isi="insert into tb_kinerja (id_pegawai,tgl,jam,uraian,before,after,id_cabang ) values ('$idpegawai','$tgl','$jam','$uraian','$fileName','$fileName3','$cabang')";
				if ($result){
					
				move_uploaded_file($_FILES['file2']['tmp_name'], "../assets/img/filekinerja/".$fileName);
				move_uploaded_file($_FILES['file3']['tmp_name'], "../assets/img/filekinerja/".$fileName3);
					$hasil='1';
				}else{
					$hasil='2';
				}
		
		
	} else {
		$hasil='3';
	}
	if ($hasil == '1'){
				header("Location: ../main.php?mod=kinerja&code=1");
			}elseif ($hasil == '2'){
				header("Location: ../main.php?mod=kinerja&code=2");
			} else {
				header("Location: ../main.php?mod=kinerja&code=3");
			}
			
			
}elseif($_GET['mod'] == 'patroli'){

	//echo $jam=$_POST['jam'];
	
		// if (isset($_POST['jam']) && isset($_POST['keterangan']) && isset($_POST['vol'])){		
		if ( isset($_POST['keterangan'])){		
			$jam= date('H:i:s'); //$_POST['jam'];
			$tgl=date('Y-m-d');
			$keterangan=$_POST['keterangan'];
			$lokasi_patroli=$_POST['lokasi_patroli'];
			$lokasi_patroli=$_POST['lokasi_patroli'];
			$lokasi_patroli=$_POST['lokasi_patroli'];
			$lokasi_patroli=$_POST['lokasi_patroli'];
			$cabang=$_POST['cabang'];
			$id_pegawai=$_POST['id_pegawai'];
			$namatgl=date('ymd',strtotime($tgl));
			$namajam=date('Hms',strtotime($jam));

			$result = mysqli_query($mysqli, "select p.tmpt_tugas from tb_pegawai p  where p.id_pegawai='$id_pegawai'");
			while($user_data = mysqli_fetch_array($result)) {
				$tmpt_tugas=$user_data['tmpt_tugas'];
			}
	
			if(!empty($_FILES['file2']['name'])){
				$file= $_FILES['file2']['name'];
				$file_ext= strtolower(end(explode('.', $file)));
				$fileName=$idpegawai.$namatgl.$namajam."1.".$file_ext;
			} else{
				$fileName="";
			}
			
	
					$result = mysqli_query($mysqli, "insert into tb_patroli (`id_pegawai`,`tanggal`,`jam`,`keterangan`,`foto1`,`id_cabang`,`nama_pin`,`id_tmpt`,`id_pin_patroli`,`nama_tmpt`) 
					values ('$idpegawai','$tgl','$jam','$keterangan','$fileName','$cabang','$nama_pin','$id_tmpt','$id_pin_patroli','$nama_tmpt')");
					$isi="insert into tb_patroli (`id_pegawai`,`tgl`,`jam`,`keterangan`,`foto1`,`foto2`,`id_cabang`,`foto3`,`foto4`,`lokasi_patroli`) values ('$idpegawai','$tgl','$jam','$keterangan','$fileName','$fileName3','$cabang','$fileName4','$fileName5','$lokasi_patroli')";
					if ($result){
						
					move_uploaded_file($_FILES['file2']['tmp_name'], "../assets/img/filepatroli/".$fileName);
					$source_img = "../assets/img/filepatroli/".$fileName;
					$destination_img = "../assets/img/filepatroli/tumb".$fileName;
					$d = compress($source_img, $destination_img, 75);
						$hasil='1';
					}else{
						$hasil='2';
					}
			
			
		} else {
			$hasil='3';
		}
		if ($hasil == '1'){
					header("Location: ../main.php?mod=patroli&code=1");
		}elseif ($hasil == '2'){
					header("Location: ../main.php?mod=patroli&code=2".$isi);
		} else {
					header("Location: ../main.php?mod=patroli&code=3");
		}
				
				
	}
 elseif($_GET['mod'] == 'editfoto'){

//echo $jam=$_POST['jam'];
// echo $idpegawai;

		$file= $_FILES['file2']['name'];
		if(!empty($file) || isset($file)){
			
			if (!isset($_FILES['file2']) || $_FILES['file2']['error'] !== UPLOAD_ERR_OK) {
				echo json_encode(['status' => 'error', 'message' => 'File tidak dikirim atau terjadi kesalahan saat upload']);
				header("Location: ../main.php?mod=editfoto&code=2");
    			// exit;
			}
			$curl = curl_init();
			$cfile = new CURLFile($fotofile, $_FILES['file2']['type'], $_FILES['file2']['name']);
			
			curl_setopt_array($curl, array(
				CURLOPT_URL => "http://91.108.111.67:5000/encode",
				CURLOPT_RETURNTRANSFER => true,
				CURLOPT_POST => true,
				CURLOPT_POSTFIELDS => array(
					"id_pegawai" => $idpegawai,
					"foto" => $cfile
				),
			));
			$response = curl_exec($curl);
				header("Location: ../main.php?mod=editfoto&code=2");
			
			
		}else {
				header("Location: ../main.php?mod=editfoto&code=2");
		
		}
			
			
}
}
?>