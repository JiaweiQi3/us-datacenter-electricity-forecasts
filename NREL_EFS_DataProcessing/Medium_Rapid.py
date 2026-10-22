from pathlib import Path
import pandas as pd

# File Path
EFS_DIR = Path(__file__).resolve().parent.parent / "EFS"
INPUT_CSV = EFS_DIR / "Medium_Rapid.csv"
OUTPUT_CSV = EFS_DIR / "result" / "nrel_medium_rapid.csv"

SCENARIO = "medium_rapid"
SCENARIO_ORIGINAL = "Medium_Rapid"
SOURCE = "NREL_EFS"

CHUNK_SIZE = 200_000

def main():

    yearly_sum = {}
    total_rows = 0

    for chunk in pd.read_csv(INPUT_CSV, chunksize=CHUNK_SIZE):

        total_rows += len(chunk)

        # only retain columns
        chunk = chunk[["Year", "LoadMW", "LocalHourID", "State"]].copy()

        # type cleaning
        chunk["Year"] = pd.to_numeric(chunk["Year"], errors="coerce")
        chunk["LoadMW"] = pd.to_numeric(chunk["LoadMW"], errors="coerce")

        chunk = chunk.dropna(subset=["Year", "LoadMW"])

        # Sanity Check
        if total_rows == len(chunk):
            print("SANITY CHECK:")

            print("Unique hours:", chunk["LocalHourID"].nunique())
            print("Unique states:", chunk["State"].nunique())
            print("Year sample:", chunk["Year"].unique()[:5])

            print("-" * 40)

        # Aggregate by 'year'
        grouped = chunk.groupby("Year")["LoadMW"].sum()

        for year, val in grouped.items():
            yearly_sum[year] = yearly_sum.get(year, 0) + val


    # construct final dataframe
    df = pd.DataFrame({
        "year": list(yearly_sum.keys()),
        "load_mwh": list(yearly_sum.values())
    })

    df = df.sort_values("year")

    # unit conversion
    df["load_twh"] = df["load_mwh"] / 1_000_000

    # metadata
    df["source"] = SOURCE
    df["scenario"] = SCENARIO
    df["scenario_original"] = SCENARIO_ORIGINAL

    df = df[[
        "year",
        "scenario",
        "scenario_original",
        "load_twh",
        "source"
    ]]

    # Output
    OUTPUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(OUTPUT_CSV, index=False)

    # Final Check
    print("\n PROCESS COMPLETE")
    print(f"Total rows processed: {total_rows}")

    print("\n Result preview:")
    print(df.head())

    print("\n Summary stats:")
    print("Min TWh:", df["load_twh"].min())
    print("Max TWh:", df["load_twh"].max())

    print("\n Saved to:")
    print(OUTPUT_CSV)


if __name__ == "__main__":
    main()