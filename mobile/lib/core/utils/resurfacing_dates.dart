/// Resurfacing (Faz C) tarih hesapları.
///
/// Saf fonksiyonlar — `now` parametresi ile test edilebilir.
class ResurfacingDates {
  ResurfacingDates._();

  /// Success sheet "Yarın" aksiyonu: yarın, aynı tarih bileşenleriyle.
  /// (Saat, hatırlatıcıda ayrıca `TimeOfDay` olarak taşınır — picker'daki
  /// varsayılan "yarın + şimdiki saat" mantığıyla birebir.)
  static DateTime tomorrow(DateTime now) => now.add(const Duration(days: 1));

  /// Success sheet "Hafta sonu" aksiyonu: sıradaki Cumartesi.
  /// Bugün Cumartesi ise bir sonraki haftanın Cumartesi'si döner.
  static DateTime nextSaturday(DateTime now) {
    var days = (DateTime.saturday - now.weekday + 7) % 7;
    if (days == 0) days = 7;
    return now.add(Duration(days: days));
  }

  /// Haftalık özet bildirimi: sıradaki Pazar `hour`:`minute`.
  /// Bugün Pazar ve saat henüz gelmediyse bugünü döner; aksi halde
  /// gelecek Pazar'ı döner. Dönen değer her zaman `now`'dan sonradır.
  static DateTime nextSundayAt(DateTime now, {int hour = 19, int minute = 0}) {
    final days = (DateTime.sunday - now.weekday + 7) % 7;
    // Gün aritmetiği DateTime kurucusuyla yapılır (duvar saati korunur).
    var candidate = DateTime(now.year, now.month, now.day + days, hour, minute);

    if (!candidate.isAfter(now)) {
      candidate = DateTime(
        candidate.year,
        candidate.month,
        candidate.day + 7,
        hour,
        minute,
      );
    }
    return candidate;
  }
}
