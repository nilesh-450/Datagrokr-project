"""Load: save the transformed DataFrame to CSV."""
from pathlib import Path

import pandas as pd


def save_to_csv(df: pd.DataFrame, path: str = "data/output.csv") -> Path:
    out = Path(path)
    out.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(out, index=False)
    return out
