using System.Text.Json;
using SomineApi.Application.DTOs.Reminders;
using SomineApi.Domain.Enums;

namespace SomineApi.Tests;

/// <summary>
/// <see cref="RepeatFrequency"/> mobil istemciyle paylaşılan bir TEL SÖZLEŞMESİDİR (wire contract).
/// Mobil <c>repeat.index</c>'i tam sayı olarak gönderiyor, sunucu da varsayılan
/// System.Text.Json davranışıyla enum'u tam sayı olarak yazıyor — yani sayısal değerler
/// <c>somine_app/lib/core/models/reminder_model.dart</c> ile birebir aynı olmak zorunda.
/// Bu testler o eşlemeyi çiviliyor; sıra kayarsa derleme değil, test kırılır.
/// </summary>
public class RepeatFrequencyWireContractTests
{
    private static readonly JsonSerializerOptions WebOptions = new(JsonSerializerDefaults.Web);

    /// <summary>
    /// Mobildeki <c>RepeatFrequency</c> enum'unun sırası (reminder_model.dart).
    /// Bu tabloyu değiştirmek, yayında olan uygulama sürümlerini bozar.
    /// </summary>
    [Theory]
    [InlineData(0, RepeatFrequency.None)]
    [InlineData(1, RepeatFrequency.Daily)]
    [InlineData(2, RepeatFrequency.Weekly)]
    [InlineData(3, RepeatFrequency.Monthly)]
    [InlineData(4, RepeatFrequency.Yearly)]
    [InlineData(5, RepeatFrequency.Weekdays)]
    [InlineData(6, RepeatFrequency.Weekends)]
    [InlineData(7, RepeatFrequency.CustomMinutes)]
    [InlineData(8, RepeatFrequency.CustomDays)]
    public void NumericValue_MatchesMobileEnumIndex(int mobileIndex, RepeatFrequency expected)
    {
        Assert.Equal(mobileIndex, (int)expected);
    }

    [Fact]
    public void MemberCount_MatchesMobile_SoNewValuesAreAddedInLockstep()
    {
        // Mobilde 9 üye var. Yeni bir tekrar tipi eklerken bu sayıyı ve mobil enum'u birlikte güncelleyin.
        Assert.Equal(9, Enum.GetValues<RepeatFrequency>().Length);
    }

    // ---------- Gelen istek: mobil int → sunucu enum ----------

    [Fact]
    public void CreateRequest_DeserializesMobileSeven_AsCustomMinutes()
    {
        // Kullanıcı "15 dakikada bir" seçtiğinde mobil repeatType olarak 7 gönderiyor.
        const string json = """
        {
            "itemId": "8f1f5f4c-2c2f-4a9a-9c3f-2b0f9a5d1e77",
            "reminderDate": "2026-08-01",
            "reminderHour": 9,
            "reminderMinute": 0,
            "repeatType": 7,
            "customRepeatMinutes": 15
        }
        """;

        var request = JsonSerializer.Deserialize<CreateReminderRequest>(json, WebOptions);

        Assert.NotNull(request);
        Assert.Equal(RepeatFrequency.CustomMinutes, request!.RepeatType);
        Assert.Equal(15, request.CustomRepeatMinutes);
    }

    [Fact]
    public void CreateRequest_DeserializesMobileEight_AsCustomDays()
    {
        const string json = """
        {
            "itemId": "8f1f5f4c-2c2f-4a9a-9c3f-2b0f9a5d1e77",
            "reminderDate": "2026-08-01",
            "reminderHour": 9,
            "reminderMinute": 0,
            "repeatType": 8,
            "customRepeatDays": 3
        }
        """;

        var request = JsonSerializer.Deserialize<CreateReminderRequest>(json, WebOptions);

        Assert.NotNull(request);
        Assert.Equal(RepeatFrequency.CustomDays, request!.RepeatType);
        Assert.Equal(3, request.CustomRepeatDays);
    }

    // ---------- Giden yanıt: sunucu enum → mobil int ----------

    [Theory]
    [InlineData(RepeatFrequency.CustomMinutes, 7)]
    [InlineData(RepeatFrequency.CustomDays, 8)]
    [InlineData(RepeatFrequency.None, 0)]
    [InlineData(RepeatFrequency.Weekends, 6)]
    public void ReminderDto_SerializesRepeatTypeAsMobileIndex(RepeatFrequency repeat, int expectedIndex)
    {
        var dto = new ReminderDto(
            Guid.NewGuid(),
            Guid.NewGuid(),
            new DateOnly(2026, 8, 1),
            9,
            0,
            repeat,
            IsActive: true,
            CustomRepeatDays: null,
            CustomRepeatMinutes: null,
            CreatedAt: DateTime.UtcNow);

        using var document = JsonDocument.Parse(JsonSerializer.Serialize(dto, WebOptions));

        // JsonStringEnumConverter kayıtlı olmadığı için sayı bekliyoruz; string'e geçilirse
        // mobildeki int okuma yolu sessizce None'a düşerdi.
        var repeatType = document.RootElement.GetProperty("repeatType");
        Assert.Equal(JsonValueKind.Number, repeatType.ValueKind);
        Assert.Equal(expectedIndex, repeatType.GetInt32());
    }

    // ---------- Gidiş-dönüş ----------

    [Theory]
    [InlineData(RepeatFrequency.CustomMinutes)]
    [InlineData(RepeatFrequency.CustomDays)]
    public void RoundTrip_PreservesRepeatType(RepeatFrequency repeat)
    {
        var original = new CreateReminderRequest(
            Guid.NewGuid(),
            new DateOnly(2026, 8, 1),
            9,
            0,
            repeat,
            CustomRepeatDays: repeat == RepeatFrequency.CustomDays ? 3 : null,
            CustomRepeatMinutes: repeat == RepeatFrequency.CustomMinutes ? 15 : null);

        var roundTripped = JsonSerializer.Deserialize<CreateReminderRequest>(
            JsonSerializer.Serialize(original, WebOptions), WebOptions);

        Assert.NotNull(roundTripped);
        Assert.Equal(repeat, roundTripped!.RepeatType);
    }

    // ---------- Veritabanı gösterimi ----------

    [Fact]
    public void EnumNames_AreStable_BecauseDatabaseStoresThemAsText()
    {
        // repeat_type kolonu HasConversion<string>() ile METİN olarak saklanıyor. Sayısal değerleri
        // değiştirmek saklanan metni etkilemez; ama isimleri değiştirmek mevcut satırları okunamaz kılar.
        Assert.Equal("CustomMinutes", RepeatFrequency.CustomMinutes.ToString());
        Assert.Equal("CustomDays", RepeatFrequency.CustomDays.ToString());
        Assert.Equal("None", RepeatFrequency.None.ToString());
    }
}
