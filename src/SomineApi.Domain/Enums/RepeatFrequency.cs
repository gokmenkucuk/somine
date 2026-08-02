namespace SomineApi.Domain.Enums;

/// <summary>
/// Hatırlatıcı tekrar tipi.
/// </summary>
/// <remarks>
/// TEL ÜZERİNDEKİ SÖZLEŞME (WIRE CONTRACT): Bu enum JSON'a <b>tam sayı</b> olarak serileştirilir
/// (projede <c>JsonStringEnumConverter</c> kayıtlı değil), veritabanına ise <b>metin</b> olarak
/// yazılır (<c>ReminderConfiguration</c> → <c>HasConversion&lt;string&gt;()</c>).
/// Mobil istemci <c>repeat.index</c>'i tam sayı olarak gönderdiğinden, buradaki sıralama
/// <c>somine_app/lib/core/models/reminder_model.dart</c> içindeki <c>RepeatFrequency</c> ile
/// BİREBİR aynı olmak zorundadır. Sayısal değerler bu yüzden açıkça sabitlenmiştir — sıraya
/// güvenip araya üye eklemeyin; yeni üyeleri yalnızca sonuna, yeni bir sayı vererek ve mobil
/// tarafla eşzamanlı olarak ekleyin.
/// </remarks>
public enum RepeatFrequency
{
    None = 0,
    Daily = 1,
    Weekly = 2,
    Monthly = 3,
    Yearly = 4,
    Weekdays = 5,
    Weekends = 6,
    CustomMinutes = 7,
    CustomDays = 8
}
