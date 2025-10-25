String getInitials(String text) {
  // Pisahkan teks menjadi kata-kata berdasarkan spasi
  final words = text.trim().split(' ');

  if (words.length > 1) {
    // Jika ada lebih dari satu kata, ambil huruf pertama dari dua kata pertama
    return words
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();
  } else {
    // Jika hanya satu kata, ambil dua huruf pertama
    final singleWord =
        words.firstOrNull ?? ''; // Menghindari kesalahan jika string kosong
    return singleWord.length >= 2
        ? singleWord.substring(0, 2).toUpperCase()
        : singleWord.toUpperCase();
  }
}
