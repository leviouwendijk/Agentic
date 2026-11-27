import Agentic
import Foundation
import Macros
import Schema

public extension Standard.Tools {
    /// The current moment, so agents never assume the date from training.
    @Tool("current_datetime")
    struct CurrentDatetime: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            /// IANA time zone, such as `Europe/Amsterdam`. Defaults to the
            /// system's zone.
            public let time_zone: String?

            public init(time_zone: String? = nil) {
                self.time_zone = time_zone
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            /// The current moment, ISO 8601 with offset.
            public let now: String
            /// Today's date, `yyyy-MM-dd`.
            public let today: String
            /// Lowercase English weekday, such as `tuesday`.
            public let weekday: String
            public let time_zone: String
            /// Today 00:00 up to the same time seven days later.
            public let coming_week_start: String
            public let coming_week_end: String
            /// Monday 00:00 of this week up to the next Monday.
            public let this_week_start: String
            public let this_week_end: String
        }

        public enum Failure: Error, Sendable, LocalizedError {
            case unknownTimeZone(String)
            case calendar

            public var errorDescription: String? {
                switch self {
                case .unknownTimeZone(let zone):
                    return "'\(zone)' is not a known IANA time zone identifier."
                case .calendar:
                    return "The calendar could not compute this week."
                }
            }
        }

        public static let purpose =
            "The current date and time in a time zone, with the exact windows for the coming seven days and for this week (Monday to Monday). Call it before resolving any relative date; never assume the date."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(_ input: Input, in _: CapabilityContext) async throws -> Output {
            let zone: TimeZone
            if let identifier = input.time_zone {
                guard let named = TimeZone(identifier: identifier) else {
                    throw Failure.unknownTimeZone(identifier)
                }
                zone = named
            } else {
                zone = .current
            }
            return try Self.output(at: Date(), in: zone)
        }

        public static func output(at now: Date, in zone: TimeZone) throws -> Output {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = zone
            let today = calendar.startOfDay(for: now)
            // Calendar weekdays run Sunday = 1 ... Saturday = 7.
            let sinceMonday = (calendar.component(.weekday, from: today) + 5) % 7
            guard
                let comingEnd = calendar.date(byAdding: .day, value: 7, to: today),
                let monday = calendar.date(byAdding: .day, value: -sinceMonday, to: today),
                let nextMonday = calendar.date(byAdding: .day, value: 7, to: monday)
            else {
                throw Failure.calendar
            }

            let timestamp = ISO8601DateFormatter()
            timestamp.timeZone = zone
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.timeZone = zone
            formatter.locale = Locale(identifier: "en_US_POSIX")

            formatter.dateFormat = "yyyy-MM-dd"
            let date = formatter.string(from: now)
            formatter.dateFormat = "EEEE"
            let weekday = formatter.string(from: now).lowercased()

            return .init(
                now: timestamp.string(from: now),
                today: date,
                weekday: weekday,
                time_zone: zone.identifier,
                coming_week_start: timestamp.string(from: today),
                coming_week_end: timestamp.string(from: comingEnd),
                this_week_start: timestamp.string(from: monday),
                this_week_end: timestamp.string(from: nextMonday)
            )
        }
    }
}
