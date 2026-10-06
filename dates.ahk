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
