from unittest.mock import MagicMock, patch

import pandas as pd
import pytest
import requests

from etl.extract import fetch_data
from etl.load import save_to_csv
from etl.transform import transform_data

SAMPLE = [
    {"id": 2, "name": "  bob smith ", "username": "bobby", "email": "BOB@Example.COM",
     "address": {"city": "Pune"}, "company": {"name": "Acme"}},
    {"id": 1, "name": "alice jones", "username": "ali", "email": "alice@test.org",
     "address": {"city": "Delhi"}, "company": {"name": "Globex"}},
    {"id": 1, "name": "alice jones", "username": "ali", "email": "alice@test.org",
     "address": {"city": "Delhi"}, "company": {"name": "Globex"}},  # duplicate
    {"id": 3, "name": "No Email", "username": "x", "email": None,
     "address": {"city": "Goa"}, "company": {"name": "Initech"}},   # invalid
]


# ---------- extract ----------
@patch("etl.extract.requests.get")
def test_fetch_data_returns_list(mock_get):
    mock_get.return_value = MagicMock(json=lambda: SAMPLE, raise_for_status=lambda: None)
    assert fetch_data("http://fake") == SAMPLE


@patch("etl.extract.requests.get")
def test_fetch_data_raises_on_http_error(mock_get):
    resp = MagicMock()
    resp.raise_for_status.side_effect = requests.HTTPError("500")
    mock_get.return_value = resp
    with pytest.raises(requests.HTTPError):
        fetch_data("http://fake")


@patch("etl.extract.requests.get")
def test_fetch_data_rejects_non_list(mock_get):
    mock_get.return_value = MagicMock(json=lambda: {"a": 1}, raise_for_status=lambda: None)
    with pytest.raises(ValueError):
        fetch_data("http://fake")


# ---------- transform ----------
def test_transform_cleans_and_dedupes():
    df = transform_data(SAMPLE)
    assert list(df["id"]) == [1, 2]            # dupe + null-email dropped, sorted
    assert df.loc[1, "name"] == "Bob Smith"    # stripped + title-cased
    assert df.loc[1, "email"] == "bob@example.com"


def test_transform_flattens_nested_fields():
    df = transform_data(SAMPLE)
    assert df.loc[0, "city"] == "Delhi"
    assert df.loc[0, "company"] == "Globex"


def test_transform_adds_email_domain():
    df = transform_data(SAMPLE)
    assert list(df["email_domain"]) == ["test.org", "example.com"]


def test_transform_empty_input():
    df = transform_data([])
    assert df.empty and "email_domain" in df.columns


# ---------- load ----------
def test_save_to_csv_roundtrip(tmp_path):
    df = transform_data(SAMPLE)
    out = save_to_csv(df, tmp_path / "nested" / "out.csv")
    assert out.exists()
    pd.testing.assert_frame_equal(pd.read_csv(out), df, check_dtype=False)
