#Requires AutoHotkey v2.0

ValidateYear(year) {
    if !RegExMatch(year, "^\d{4}\z") || year < 1900 || year > 9999
        throw ValueError("FinancialYearEnding must be a four-digit year from 1900 to 9999.")
}

FinancialYearEnd(year) {
    ValidateYear(year)
    return "30/06/" year
}

FinancialYearLabel(year) {
    ValidateYear(year)
    return Format("{:04}-{:02}", year - 1, Mod(year, 100))
}

QuarterEnd(year, quarter) {
    ValidateYear(year)
    if !RegExMatch(quarter, "^[1-4]\z")
        throw ValueError("Quarter must be 1, 2, 3 or 4.")
    return ["30/09/", "31/12/", "31/03/", "30/06/"][quarter] (quarter <= 2 ? year - 1 : year)
}

AustralianDate(timestamp := "") {
    return FormatTime(timestamp, "dd/MM/yyyy")
}

FinancialYearStart(year) {
    ValidateYear(year)
    return "01/07/" (year - 1)
}

FinancialYearRange(year) {
    return FinancialYearStart(year) " to " FinancialYearEnd(year)
}

QuarterStart(year, quarter) {
    ValidateYear(year)
    if !RegExMatch(quarter, "^[1-4]\z")
        throw ValueError("Quarter must be 1, 2, 3 or 4.")
    return ["01/07/", "01/10/", "01/01/", "01/04/"][quarter] (quarter <= 2 ? year - 1 : year)
}

QuarterRange(year, quarter) {
    return QuarterStart(year, quarter) " to " QuarterEnd(year, quarter)
}

IsoDate(timestamp := "") {
    return FormatTime(timestamp, "yyyy-MM-dd")
}

FileDate(timestamp := "") {
    return FormatTime(timestamp, "yyyyMMdd")
}

DaysInMonth(year, month) {
    if !RegExMatch(year, "^[0-9]{4}\z") || year < 1601 || year > 9999
        throw ValueError("Calendar year must be from 1601 to 9999.")
    if !RegExMatch(month, "^[0-9]{1,2}\z") || month < 1 || month > 12
        throw ValueError("Month must be from 1 to 12.")
    if month = 2
        return Mod(year, 400) = 0 || (Mod(year, 4) = 0 && Mod(year, 100) != 0) ? 29 : 28
    return [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][Integer(month)]
}

CalendarDate(year, month, day, style := "AU") {
    lastDay := DaysInMonth(year, month)
    if !RegExMatch(day, "^[0-9]{1,2}\z") || day < 1 || day > lastDay
        throw ValueError("Day is outside the selected calendar month.")
    switch style {
        case "AU": return Format("{:02}/{:02}/{:04}", day, month, year)
        case "ISO": return Format("{:04}-{:02}-{:02}", year, month, day)
        case "File": return Format("{:04}{:02}{:02}", year, month, day)
        default: throw ValueError("Date style must be AU, ISO or File.")
    }
}

ParseStrictDate(text) {
    if Type(text) != "String" || StrLen(text) > 64
        throw ValueError("Enter one date of at most 64 characters.")
    text := Trim(text, " `t`r`n")
    if RegExMatch(text, "^([0-9]{2})/([0-9]{2})/([0-9]{4})\z", &parts)
        date := {Year: Integer(parts[3]), Month: Integer(parts[2]), Day: Integer(parts[1])}
    else if RegExMatch(text, "^([0-9]{4})-([0-9]{2})-([0-9]{2})\z", &parts)
        date := {Year: Integer(parts[1]), Month: Integer(parts[2]), Day: Integer(parts[3])}
    else if RegExMatch(text, "^([0-9]{4})([0-9]{2})([0-9]{2})\z", &parts)
        date := {Year: Integer(parts[1]), Month: Integer(parts[2]), Day: Integer(parts[3])}
    else
        throw ValueError("Use dd/MM/yyyy, yyyy-MM-dd or yyyyMMdd with a four-digit year.")
    CalendarDate(date.Year, date.Month, date.Day)
    return date
}

ConvertDate(text, style := "ISO") {
    date := ParseStrictDate(text)
    return CalendarDate(date.Year, date.Month, date.Day, style)
}

MonthStart(year, month) {
    return CalendarDate(year, month, 1)
}

MonthEnd(year, month) {
    return CalendarDate(year, month, DaysInMonth(year, month))
}

MonthRange(year, month) {
    return MonthStart(year, month) " to " MonthEnd(year, month)
}

MonthLabel(year, month) {
    DaysInMonth(year, month)
    names := ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    return names[Integer(month)] " " year
}

FinancialYearMonthEnds(year) {
    ValidateYear(year)
    result := ""
    Loop 12 {
        month := Mod(A_Index + 5, 12) + 1
        result .= (A_Index = 1 ? "" : "`n") MonthEnd(month >= 7 ? year - 1 : year, month)
    }
    return result
}

DaysBetween(text) {
    if Type(text) != "String" || StrLen(text) > 200
        throw ValueError("Enter two dates in at most 200 characters.")
    if !RegExMatch(Trim(text, " `t`r`n"), "i)^(\S+)(?:[ `t]+to[ `t]+|(?:[ `t]*\R)+[ `t]*)(\S+)\z", &parts)
        throw ValueError("Enter two dates on separate lines, or as: date to date.")
    first := ParseStrictDate(parts[1])
    second := ParseStrictDate(parts[2])
    return String(DateDiff(CalendarDate(second.Year, second.Month, second.Day, "File"), CalendarDate(first.Year, first.Month, first.Day, "File"), "Days"))
}

AustralianDateOf(date) {
    return CalendarDate(date.Year, date.Month, date.Day)
}

; DateAdd returns a five-digit year after 9999 and an empty string before 1601, so check its result.
DateFromDays(date, days) {
    stamp := DateAdd(CalendarDate(date.Year, date.Month, date.Day, "File"), days, "Days")
    if StrLen(stamp) != 14
        throw ValueError("The result must fall between 1601 and 9999.")
    return ParseStrictDate(SubStr(stamp, 1, 8))
}

; As Excel's EDATE does, a day the target month lacks becomes that month's last day.
DateFromMonths(date, months) {
    index := date.Year * 12 + date.Month - 1 + months
    year := index // 12
    if year < 1601 || year > 9999
        throw ValueError("The result must fall between 1601 and 9999.")
    month := Mod(index, 12) + 1
    return {Year: year, Month: month, Day: Min(date.Day, DaysInMonth(year, month))}
}

DateOffset(text) {
    if Type(text) != "String" || StrLen(text) > 64
        throw ValueError("Enter one date offset of at most 64 characters.")
    if !RegExMatch(Trim(text, " `t`r`n"), "i)^(\S+)[ `t]+([+-])[ `t]*([0-9]{1,5})[ `t]+(day|month)s?\z", &parts)
        throw ValueError("Enter a date, + or - and a number of days or months, such as 31/01/2024 + 1 month.")
    date := ParseStrictDate(parts[1])
    count := parts[2] = "-" ? -Integer(parts[3]) : Integer(parts[3])
    return AustralianDateOf(parts[4] = "day" ? DateFromDays(date, count) : DateFromMonths(date, count))
}

; Payment terms are written out in full, because shorthand such as '30 days EOM' is read more than one way.
DueDate(text) {
    if Type(text) != "String" || StrLen(text) > 100
        throw ValueError("Enter an invoice date and terms in at most 100 characters.")
    if !RegExMatch(Trim(text, " `t`r`n"), "^(\S+?),?[ `t]+(\S.*)\z", &parts)
        throw ValueError("Enter an invoice date followed by its terms, such as 15/01/2026 net 30.")
    date := ParseStrictDate(parts[1])
    terms := parts[2]
    if RegExMatch(terms, "i)^(?:net[ `t]+([0-9]{1,4})|([0-9]{1,4})[ `t]+days?)\z", &found)
        return AustralianDateOf(DateFromDays(date, Integer(found[1] found[2])))
    if RegExMatch(terms, "i)^([0-9]{1,4})[ `t]+days?[ `t]+after[ `t]+month[ `t]+end\z", &found)
        return AustralianDateOf(DateFromDays({Year: date.Year, Month: date.Month, Day: DaysInMonth(date.Year, date.Month)}, Integer(found[1])))
    if RegExMatch(terms, "i)^([0-9]{1,2})(?:st|nd|rd|th)?[ `t]+of[ `t]+(?:the[ `t]+)?(?:next|following)[ `t]+month\z", &found) {
        next := DateFromMonths({Year: date.Year, Month: date.Month, Day: 1}, 1)
        day := Integer(found[1])
        if day < 1 || day > DaysInMonth(next.Year, next.Month)
            throw ValueError(MonthLabel(next.Year, next.Month) " has no day " day "; check the terms.")
        return CalendarDate(next.Year, next.Month, day)
    }
    throw ValueError("Use terms such as net 30, 30 days, 30 days after month end or 20th of next month.")
}

; Skips Saturdays and Sundays only. Public holidays are not checked.
NextBusinessDay(text) {
    date := ParseStrictDate(text)
    weekday := FormatTime(CalendarDate(date.Year, date.Month, date.Day, "File"), "WDay")
    return AustralianDateOf(DateFromDays(date, weekday = 6 ? 3 : weekday = 7 ? 2 : 1))
}

; Days past the due date at the as-at date, in 30-day steps.
AgeingBucket(text) {
    overdue := Integer(DaysBetween(text))
    if overdue <= 0
        return "Current"
    for edge in [30, 60, 90] {
        if overdue <= edge
            return (edge - 29) " to " edge " days overdue"
    }
    return "Over 90 days overdue"
}

; Decimal hours between 2 times on one day. An end time earlier than the start is refused, not read as overnight.
DurationHours(text) {
    if Type(text) != "String" || StrLen(text) > 64
        throw ValueError("Enter 2 times in at most 64 characters.")
    if !RegExMatch(Trim(text, " `t`r`n"), "i)^([0-9]{1,2}):([0-9]{2})(?:[ `t]+to[ `t]+|[ `t]*-[ `t]*|[ `t]*\R[ `t]*)([0-9]{1,2}):([0-9]{2})(?:[ `t]+round[ `t]+(up|nearest)[ `t]+([0-9]{1,2}))?\z", &parts)
        throw ValueError("Enter 24-hour times such as 09:00 to 17:30, optionally followed by round up 6 or round nearest 15.")
    start := MinutesOfDay(parts[1], parts[2], false)
    finish := MinutesOfDay(parts[3], parts[4], true)
    if finish <= start
        throw ValueError("The end time must be later than the start time on the same day. Split an overnight period at 24:00.")
    minutes := finish - start
    if parts[5] != "" {
        unit := Integer(parts[6])
        if unit < 1 || unit > 60
            throw ValueError("Round to a unit from 1 to 60 minutes.")
        ; Nearest rounds an exact half unit up.
        minutes := parts[5] = "up" ? (minutes + unit - 1) // unit * unit : (2 * minutes + unit) // (2 * unit) * unit
    }
    ; Hundredths of an hour, to the nearest; minutes * 5 / 3 never ends in exactly a half.
    hundredths := (10 * minutes + 3) // 6
    return hundredths // 100 "." Format("{:02}", Mod(hundredths, 100))
}

MinutesOfDay(hours, minutes, isEnd) {
    hours := Integer(hours), minutes := Integer(minutes)
    if minutes > 59 || hours > 24 || hours = 24 && (!isEnd || minutes > 0)
        throw ValueError("Times run from 00:00 to 23:59; only an end time may be 24:00.")
    return hours * 60 + minutes
}

PeriodOfDate(text) {
    date := ParseStrictDate(text)
    return "FY " FinancialYearLabel(date.Month >= 7 ? date.Year + 1 : date.Year) " Q" (Floor(Mod(date.Month + 5, 12) / 3) + 1)
}

MonthFromDate(text, part) {
    date := ParseStrictDate(text)
    switch part {
        case "Start": return MonthStart(date.Year, date.Month)
        case "End": return MonthEnd(date.Year, date.Month)
        case "Range": return MonthRange(date.Year, date.Month)
        case "Label": return MonthLabel(date.Year, date.Month)
        default: throw ValueError("Unknown month result.")
    }
}
