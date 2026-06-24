FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8087
CMD ["uvicorn", "services.collaboration_service.src.main:app", "--host", "0.0.0.0", "--port", "8087"]
