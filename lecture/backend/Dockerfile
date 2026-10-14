# --- Build stage ---
FROM python:3.12-slim AS builder

WORKDIR /app

# Create a virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
# Use && to execute the commands in sequence
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt


# --- Runtime stage ---
FROM python:3.12-slim AS runner
WORKDIR /app

# Copy the entire virtual environment from the build stage
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy the application code into place
COPY . /app/

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]