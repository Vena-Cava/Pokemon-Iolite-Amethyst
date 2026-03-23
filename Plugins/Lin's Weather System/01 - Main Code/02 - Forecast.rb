#===============================================================================
# * Weather System Forecast
#===============================================================================

def pbWeatherForecast(zone)
  weatherNow = WeatherConfig.weather_names[$WeatherSystem.actualWeather[zone].mainWeather]
  weatherNow2 = WeatherConfig.weather_names[$WeatherSystem.actualWeather[zone].secondWeather]
  weatherNext = WeatherConfig.weather_names[$WeatherSystem.nextWeather[zone].mainWeather]
  weatherNext2 = WeatherConfig.weather_names[$WeatherSystem.nextWeather[zone].secondWeather]
  weatherStart = $WeatherSystem.actualWeather[zone].startTime
  weatherEnd = $WeatherSystem.actualWeather[zone].endTime
  pbMessage(_INTL("The weather in this zone has been {1}, with chance of some places having {2}, since {3}:{4}.", weatherNow.downcase, weatherNow2.downcase, weatherStart.hour, weatherStart.min))
  pbMessage(_INTL("The weather will change at {1}:{2} to {3} with chance of {4} on some places.", weatherEnd.hour, weatherEnd.min, weatherNext.downcase, weatherNext2.downcase))
end