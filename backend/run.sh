#!/bin/bash
# Run the FastAPI development server

cd "$(dirname "$0")"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Run the server
echo "Starting FOREX AI API server..."
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
