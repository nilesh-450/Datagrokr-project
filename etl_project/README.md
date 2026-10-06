# ETL Pipeline + Tests (Python + pytest)

Fetches users from a REST API → transforms with pandas → saves to CSV.

## Setup
    python -m venv venv
    source venv/bin/activate      # Windows: venv\Scripts\activate
    pip install -r requirements.txt

## Run
    python -m etl.pipeline        # writes data/output.csv

## Test
    pytest -v
