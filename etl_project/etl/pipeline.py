"""Run the full ETL pipeline:  python -m etl.pipeline"""
import logging

from etl.extract import fetch_data
from etl.load import save_to_csv
from etl.transform import transform_data

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)


from typing import Optional
def run(url: Optional[str] = None, output: str = "data/output.csv") -> None:
    log.info("Extracting...")
    raw = fetch_data(url) if url else fetch_data()
    log.info("Fetched %d records", len(raw))

    log.info("Transforming...")
    df = transform_data(raw)

    log.info("Loading...")
    path = save_to_csv(df, output)
    log.info("Saved %d rows to %s", len(df), path)


if __name__ == "__main__":
    run()
