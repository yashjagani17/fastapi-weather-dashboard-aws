import httpx
from models.models import (
    CityResponse,
    ForecastResponse,
    ThreeDayForecastResponse,
    WeatherResponse,
)
from pydantic import TypeAdapter


class OpenWeatherAPIService:
    def __init__(self, client: httpx.AsyncClient):
        self.client = client

    async def _get(self, url: str, params: dict):
        response = await self.client.get(url, params=params)
        response.raise_for_status()
        return response.json()

    async def search_cities(self, query: str) -> list[CityResponse]:
        data = await self._get("/geo/1.0/direct", {"q": query, "limit": 5})
        return TypeAdapter(list[CityResponse]).validate_python(data)

    async def get_weather(self, lat: float, lon: float) -> WeatherResponse:
        return await self._get(
            "/data/2.5/weather", {"lat": lat, "lon": lon, "units": "metric"}
        )

    async def get_forecast(self, lat: float, lon: float) -> ForecastResponse:
        return await self._get(
            "/data/2.5/forecast", {"lat": lat, "lon": lon, "cnt": 24, "units": "metric"}
        )

    async def get_3day_forecast(
        self, lat: float, lon: float
    ) -> ThreeDayForecastResponse:
        data = await self.get_forecast(lat, lon)
        return ThreeDayForecastResponse(
            forecasts=data.get("list", [])[7::8],
            city=data.get("city"),
        )
