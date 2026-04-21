FROM python:3.13-slim
EXPOSE 8000

RUN adduser --disabled-password app
WORKDIR /app
RUN chown -R app:app /app


COPY --chown=app:app requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY --chown=app:app . .

USER app

ENV PYTHONPATH=/app/api

CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
