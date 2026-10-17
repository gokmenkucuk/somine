// Bilerek kök ad alanında: ResourceManagerStringLocalizerFactory, kaynak dosyanın adını
// "<RootNamespace>.<ResourcesPath>.<tipin kök ad alanı çıkarılmış tam adı>" olarak kurar.
// Tip SomineWeb.SharedResource olduğu için kaynak Resources/SharedResource.resx ile eşleşir.
namespace SomineWeb;

/// <summary>
/// Resources/SharedResource.resx (Türkçe, nötr) ve SharedResource.en.resx için işaretçi tip.
/// Sitedeki tüm kısa arayüz metinleri tek bir kaynak dosyasında toplanır; böylece iki dil
/// arasındaki anahtar eşitliği tek bir dosya çiftinde denetlenebilir.
/// </summary>
public sealed class SharedResource
{
}
