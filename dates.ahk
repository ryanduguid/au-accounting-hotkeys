#Requires AutoHotkey v2.0

ValidateYear(year) {
    if !RegExMatch(year, "^\d{4}$") || year < 1900 || year > 9999
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
    if !RegExMatch(quarter, "^[1-4]$")
        throw ValueError("Quarter must be 1, 2, 3 or 4.")
    return ["30/09/", "31/12/", "31/03/", "30/06/"][quarter] (quarter <= 2 ? year - 1 : year)
}

AustralianDate(timestamp := "") {
    return FormatTime(timestamp, "dd/MM/yyyy")
}
