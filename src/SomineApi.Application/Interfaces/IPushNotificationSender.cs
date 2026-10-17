namespace SomineApi.Application.Interfaces;

/// <summary>
/// Cihazlara uzak bildirim (push) gönderen alt seviye servis. Üretimde Firebase Cloud Messaging
/// (FCM → APNs) kullanılır; testlerde sahte (fake) bir uygulama ile değiştirilir.
/// </summary>
public interface IPushNotificationSender
{
    /// <summary>
    /// Gönderim yapılandırılmış mı (kimlik bilgisi bulundu mu)? <c>false</c> ise çağıran
    /// gönderimi sessizce atlar.
    /// </summary>
    bool IsConfigured { get; }

    /// <summary>
    /// Mesajları gönderir. Tek tek mesaj hataları istisna fırlatmaz; sonuçta raporlanır.
    /// </summary>
    Task<PushSendResult> SendAsync(IReadOnlyList<PushMessage> messages, CancellationToken cancellationToken = default);
}

/// <param name="Token">FCM kayıt token'ı.</param>
/// <param name="Title">Bildirim başlığı (cihaz diline göre yerelleştirilmiş).</param>
/// <param name="Body">Bildirim metni.</param>
/// <param name="Data">İstemcinin dokunuşta doğru ekranı açması için yük (<c>type</c>, kimlikler).</param>
public sealed record PushMessage(
    string Token,
    string Title,
    string Body,
    IReadOnlyDictionary<string, string> Data);

/// <param name="SuccessCount">Başarıyla iletilen mesaj sayısı.</param>
/// <param name="InvalidTokens">FCM'in kayıtsız/geçersiz dediği token'lar; veritabanından silinmeli.</param>
public sealed record PushSendResult(int SuccessCount, IReadOnlyList<string> InvalidTokens)
{
    public static PushSendResult Empty { get; } = new(0, []);
}
