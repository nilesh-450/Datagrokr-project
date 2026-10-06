"""Transform: clean and reshape raw records with pandas."""
import pandas as pd

OUTPUT_COLUMNS = ["id", "name", "username", "email", "city", "company", "email_domain"]


def transform_data(records: list[dict]) -> pd.DataFrame:
    """Flatten nested JSON, clean fields, derive new columns."""
    if not records:
        return pd.DataFrame(columns=OUTPUT_COLUMNS)

    df = pd.json_normalize(records)

    df = df.rename(columns={"address.city": "city", "company.name": "company"})

    # Keep only the columns we care about (ignore any that are missing)
    df = df[[c for c in OUTPUT_COLUMNS if c in df.columns and c != "email_domain"]].copy()

    # Clean
    df["name"] = df["name"].str.strip().str.title()
    df["email"] = df["email"].str.strip().str.lower()
    df = df.dropna(subset=["id", "email"]).drop_duplicates(subset="id")

    # Derive
    df["email_domain"] = df["email"].str.split("@").str[1]

    return df.sort_values("id").reset_index(drop=True)
