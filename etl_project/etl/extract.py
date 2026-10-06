"""Extract: fetch raw records from a REST API."""
import requests

DEFAULT_URL = "https://jsonplaceholder.typicode.com/users"


def fetch_data(url: str = DEFAULT_URL, timeout: int = 10) -> list[dict]:
    """GET JSON from the API and return a list of records."""
    response = requests.get(url, timeout=timeout)
    response.raise_for_status()
    data = response.json()
    if not isinstance(data, list):
        raise ValueError("Expected the API to return a JSON list")
    return data
