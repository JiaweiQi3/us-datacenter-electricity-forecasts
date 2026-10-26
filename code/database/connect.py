import os
from sqlalchemy import create_engine, text

engine = create_engine(
    os.environ.get(
        "DC_FORECAST_DB_URL",
        "mysql+mysqlconnector://root@127.0.0.1/us_dc_energy_forecast",
    )
)

with engine.connect() as conn:
    conn.execute(text("SELECT 1"))

print("Connected successfully!")
