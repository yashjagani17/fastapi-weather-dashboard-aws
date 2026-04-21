from pydantic import BaseModel, Field


class WeatherCoord(BaseModel):
    lat: float
    lon: float


class WeatherInfo(BaseModel):
    main: str
    description: str
    icon: str


class WeatherStats(BaseModel):
    temp: float
    # feels_like: float
    # temp_min: float
    # temp_max: float
    # pressure: float
    humidity: float
    # sea_level: float
    # grnd_level: float


class WeatherWind(BaseModel):
    speed: float
    deg: int
    gust: float | None = None


class WeatherRain(BaseModel):
    one_hour: float = Field(alias="1h", default=None)


class WeatherClouds(BaseModel):
    all: int


class WeatherSys(BaseModel):
    country: str
    # sunrise: int
    # sunset: int


class ForecastStats(BaseModel):
    temp: float
    # feels_like: float
    # temp_min: float
    # temp_max: float
    # pressure: int
    # sea_level: int
    # grnd_level: int
    humidity: int
    # temp_kf: float


class ForecastInfo(BaseModel):
    main: str
    description: str
    icon: str


class ForecastClouds(BaseModel):
    all: int


class ForecastWinds(BaseModel):
    speed: float
    deg: int
    gust: float | None = None


class ForecastRain(BaseModel):
    three_hour: float = Field(alias="3h", default=None)


class ForecastSnow(BaseModel):
    three_hour: float = Field(alias="3h", default=None)


class ForecastSys(BaseModel):
    pod: str


class ForecastItem(BaseModel):
    main: ForecastStats
    weather: list[ForecastInfo]
    # clouds: ForecastClouds
    # wind: ForecastWinds
    # visibility: int
    # rain: ForecastRain | None = None
    # snow: ForecastSnow | None = None
    dt_txt: str


class ForecastCoord(BaseModel):
    lat: float
    lon: float


class ForecastCity(BaseModel):
    name: str
    country: str
    timezone: int
