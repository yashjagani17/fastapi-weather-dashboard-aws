from typing import Optional

from models.childmodels import (
    ForecastCity,
    ForecastItem,
    WeatherInfo,
    WeatherStats,
    WeatherSys,
)
from pydantic import BaseModel, Field


class CityResponse(BaseModel):
    name: str
    lat: float
    lon: float
    country: str
    state: Optional[str] | None = None


class WeatherResponse(BaseModel):
    # coord: WeatherCoord
    weather: list[WeatherInfo]
    main: WeatherStats
    # visibility: int
    # wind: WeatherWind
    # rain: WeatherRain | None = None
    # clouds: WeatherClouds
    dt: int
    sys: WeatherSys
    name: str


class ForecastResponse(BaseModel):
    forecasts: list[ForecastItem] = Field(alias="list")
    city: ForecastCity


class ThreeDayForecastResponse(BaseModel):
    forecasts: list[ForecastItem]
    city: ForecastCity
