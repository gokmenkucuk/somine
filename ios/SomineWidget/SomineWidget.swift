import WidgetKit
import SwiftUI

// Renkler air temasından birebir (lib/core/design/app_colors.dart)
private enum SomineAirColors {
    static let surfaceWhite = Color.white
    static let backgroundMint = Color(red: 0xE8 / 255, green: 0xF1 / 255, blue: 0xEF / 255)
    static let primary = Color(red: 0x68 / 255, green: 0x8E / 255, blue: 0x8B / 255)
    static let secondary = Color(red: 0x95 / 255, green: 0xC5 / 255, blue: 0xC1 / 255)
    static let headline = Color(red: 0x2D / 255, green: 0x31 / 255, blue: 0x2F / 255)
    static let body = Color(red: 0x63 / 255, green: 0x6E / 255, blue: 0x72 / 255)
    static let hint = Color(red: 0xB2 / 255, green: 0xBE / 255, blue: 0xC3 / 255)
}

struct SomineEntry: TimelineEntry {
    let date: Date
    let title: String?
    let type: String?
    let domain: String?
    let itemId: String?

    var hasItem: Bool { !(title ?? "").isEmpty }
}

struct SomineProvider: TimelineProvider {
    private static let appGroupId = "group.com.somine.app"

    func placeholder(in context: Context) -> SomineEntry {
        SomineEntry(date: Date(), title: "Kaydettiğin içerik", type: "link", domain: "somineapp.com", itemId: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SomineEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SomineEntry>) -> Void) {
        let calendar = Calendar.current
        let nextMidnight = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        )
        completion(Timeline(entries: [loadEntry()], policy: .after(nextMidnight)))
    }

    private func loadEntry() -> SomineEntry {
        let defaults = UserDefaults(suiteName: Self.appGroupId)
        return SomineEntry(
            date: Date(),
            title: defaults?.string(forKey: "widget_title"),
            type: defaults?.string(forKey: "widget_type"),
            domain: defaults?.string(forKey: "widget_domain"),
            itemId: defaults?.string(forKey: "widget_item_id")
        )
    }
}

struct SomineWidgetEntryView: View {
    var entry: SomineEntry
    @Environment(\.widgetFamily) private var family

    private var typeLabel: String {
        switch entry.type {
        case "note": return "Not"
        case "image": return "Görsel"
        default: return "Bağlantı"
        }
    }

    private var typeIcon: String {
        switch entry.type {
        case "note": return "note.text"
        case "image": return "photo"
        default: return "link"
        }
    }

    private var deepLinkURL: URL? {
        guard let itemId = entry.itemId, !itemId.isEmpty else { return nil }
        // ?homeWidget: home_widget plugin'i tıklamayı yalnız bu parametreyle algılıyor
        return URL(string: "somine://item/\(itemId)?homeWidget")
    }

    var body: some View {
        Group {
            if entry.hasItem {
                if family == .systemMedium {
                    mediumContent
                } else {
                    smallContent
                }
            } else {
                emptyContent
            }
        }
        .containerBackground(SomineAirColors.surfaceWhite, for: .widget)
        .widgetURL(deepLinkURL)
    }

    private var badge: some View {
        HStack(spacing: 4) {
            Image(systemName: typeIcon)
                .font(.system(size: 10, weight: .semibold))
            Text(typeLabel)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(SomineAirColors.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(SomineAirColors.backgroundMint, in: Capsule())
    }

    private var smallContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            badge
            Spacer(minLength: 0)
            Text(entry.title ?? "")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SomineAirColors.headline)
                .lineLimit(3)
            if let domain = entry.domain, !domain.isEmpty {
                Text(domain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SomineAirColors.hint)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mediumContent: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(SomineAirColors.secondary)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 6) {
                badge
                Text(entry.title ?? "")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SomineAirColors.headline)
                    .lineLimit(2)
                if let domain = entry.domain, !domain.isEmpty {
                    Text(domain)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SomineAirColors.body)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SoMine")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(SomineAirColors.primary)
            Spacer(minLength: 0)
            Text("Bir şeyler kaydet, sana geri gelsin.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SomineAirColors.body)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct SomineWidget: Widget {
    let kind: String = "SomineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SomineProvider()) { entry in
            SomineWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Günün Kaydı")
        .description("Kaydettiklerinden biri her gün sana geri gelsin.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
