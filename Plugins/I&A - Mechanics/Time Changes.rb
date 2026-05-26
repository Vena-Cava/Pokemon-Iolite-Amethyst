#===============================================================================
# Days of the week
#===============================================================================
def pbGetWeekdayName(wday)
  return [
      _INTL("Sunday"),
      _INTL("Monday"),
      _INTL("Tuesday"),
      _INTL("Wednesday"),
      _INTL("Thursday"),
      _INTL("Friday"),
      _INTL("Saturday")
    ][wday]
end

#===============================================================================
# Defines Midday
#===============================================================================
module PBDayNight
  # Returns true if it's the midday.
  def self.isMidday?(time = nil)
    time = pbGetTimeNow if !time
    return (time.hour >= 11 && time.hour < 13)
  end
end

#===============================================================================
# Ordinals
#===============================================================================
def getShortOrdinal(num)
  # Get the last two digits, falling back to 0.
  *_, pud, fd = num.abs.to_s.ljust(2, '0').split(//)
  if pud == '1' then
    return "#{num}th"
  end
  return "#{num}#{
    case fd
    when '1' then 'st'
    when '2' then 'nd'
    when '3' then 'rd'
    else 'th'
    end
  }"
end