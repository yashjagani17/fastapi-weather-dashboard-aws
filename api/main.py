import os
from contextlib import asynccontextmanager
from typing import Annotated

import httpx
from dotenv import load_dotenv
from fastapi import Depends, FastAPI, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from models.models import (
    CityResponse,
    ForecastResponse,
    ThreeDayForecastResponse,
    WeatherResponse,
)
from service import OpenWeatherAPIService


@asynccontextmanager
async def lifespan(app: FastAPI):
    load_dotenv()
    API_KEY = os.getenv("WEATHER_API_KEY")
    if not API_KEY:
        raise ValueError("API_KEY environment variable is not set.")
    async with httpx.AsyncClient(
        base_url="https://api.openweathermap.org", params={"appid": API_KEY}, timeout=10
    ) as client:
        app.state.weather_service = OpenWeatherAPIService(client)
        yield


app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yashjagani.com", "https://www.yashjagani.com"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_weather_service(request: Request) -> OpenWeatherAPIService:
    return request.app.state.weather_service


weather_api = Annotated[OpenWeatherAPIService, Depends(get_weather_service)]


@app.get("/")
async def root():
    return {"status": "ok"}


@app.get("/health")
async def healthcheck():
    return {"status": "healthy"}


@app.get("/api/search-city")
async def search(
    service: weather_api,
    city: str = Query(min_length=1, max_length=100),
) -> list[CityResponse]:
    return await service.search_cities(city)


@app.get("/api/get-forecast")
async def forecast(lat: float, lon: float, service: weather_api) -> ForecastResponse:
    return await service.get_forecast(lat, lon)


@app.get("/api/get-3day-forecast")
async def forecast_3day(
    lat: float, lon: float, service: weather_api
) -> ThreeDayForecastResponse:
    return await service.get_3day_forecast(lat, lon)


@app.get("/api/get-weather")
async def weather(lat: float, lon: float, service: weather_api) -> WeatherResponse:
    return await service.get_weather(lat, lon)
