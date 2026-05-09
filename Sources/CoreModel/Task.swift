public struct Task: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let description: String?
    public let subject: String
    public let defaultMinutes: Int
    public let daysMask: Int        // bit0=日, bit1=月, bit2=火, bit3=水, bit4=木, bit5=金, bit6=土
    public let isArchived: Bool
    public let startDate: String?   // "yyyy-MM-dd" or nil
    public let endDate: String?     // "yyyy-MM-dd" or nil
    public let sortOrder: Int

    public init(
        id: String,
        name: String,
        description: String?,
        subject: String,
        defaultMinutes: Int,
        daysMask: Int,
        isArchived: Bool,
        startDate: String?,
        endDate: String?,
        sortOrder: Int
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.subject = subject
        self.defaultMinutes = defaultMinutes
        self.daysMask = daysMask
        self.isArchived = isArchived
        self.startDate = startDate
        self.endDate = endDate
        self.sortOrder = sortOrder
    }
}

// bit0=日, bit1=月, bit2=火, bit3=水, bit4=木, bit5=金, bit6=土
public let dayLabels = ["日", "月", "火", "水", "木", "金", "土"]

public extension Int {
    func hasDayBit(_ dayIndex: Int) -> Bool { (self & (1 << dayIndex)) != 0 }
    func toggleDayBit(_ dayIndex: Int) -> Int { self ^ (1 << dayIndex) }
}
