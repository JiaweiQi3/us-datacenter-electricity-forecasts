# U.S. Data Center Electricity Demand Forecasts in the Age of AI

A structured MySQL database and Python analysis that compare how 16 institutions forecast U.S. electricity demand and U.S. data center electricity demand. The forecasts were collected from public reports, harmonized to TWh, and compared side by side.

*Independent study, Carnegie Mellon University, Jan.–May 2026. Advisor: Prof. Costa Samaras.* Full write-up: [`report/US_Data_Center_Load_Forecast_Report.pdf`](report/US_Data_Center_Load_Forecast_Report.pdf)

![U.S. data center electricity demand forecast ranges in 2030](range_plot/dc_forecast_2030_range_plot.png)

## Key findings

- **Data center forecasts diverge early.** Representative 2030 forecasts for U.S. data center demand range from 424 TWh (IEA) to 925 TWh (BCG). Most sources sit between 525 and 604 TWh. The largest gap between two institutions' central forecasts grows from 313 TWh in 2028 to 501 TWh in 2030.
- **Data center demand grows far faster than national demand.** Implied data center growth to 2030 is 11–22% per year. For national electricity demand it is 0.7–3.2% per year.
- **National forecasts diverge slowly but widely.** The largest gap between central forecasts is 1,053 TWh in 2030 (NREL EFS vs. BP). By 2050 it exceeds 2,100 TWh.

## Data

| | Institutions | Forecast curves | Annual values |
|---|---|---|---|
| U.S. national electricity demand | EIA, IEA, ICF, Citi, S&P Global, NREL, BP, Princeton, LCRI, LBNL | 33 | 381 |
| U.S. data center electricity demand | LBNL, EPRI, BCG, BloombergNEF, McKinsey, IEA, Rhodium, S&P Global, Jefferies | 14 | 114 |

Each source is stored as reported or with a documented processing step:

- **Tables:** EIA Annual Energy Outlook values were transcribed directly.
- **Benchmark years:** values printed in figures or text were recorded as given.
- **Digitized:** values were read from published charts at high resolution, for example EPRI, LCRI and Jefferies. They are approximate.
- **Derived:** some series were calculated from what a source reports. Examples are annual values from a stated growth rate (Citi, ICF), GW converted to TWh with TWh = GW × 8.76 (BloombergNEF), and national totals implied by data center shares (LBNL).
- **Aggregated:** NREL Electrification Futures Study hourly load profiles were summed to annual totals.

Each curve's source and scenario are recorded in its `description` field. For data center curves the `notes` field also records the processing method. All forecasts remain the work of their publishers. See the report's reference list for full citations.

The NREL values are aggregated from *Electrification Futures Study Load Profiles*: Mai, T., et al. (2020), NREL Data Catalog, [doi:10.7799/1593122](https://doi.org/10.7799/1593122), under the catalog's [dataset license](https://data.nlr.gov/node/126/license).

## Repository layout

| Path | Contents |
|---|---|
| `us_dc_energy_forecast_database.sql` | Schema: 4 tables in a metadata–value design (`forecast_metadata`, `forecast_values`, `dc_forecast_metadata`, `dc_forecast_values`) |
| `Forecast_SQL/` | One insert script per forecast curve (`01`–`33` national, `001`–`014` data center), the two analysis queries, and the ER diagram (`ERD.mwb`, MySQL Workbench) |
| `build_database.sh` | Loads the schema and every insert script into MySQL |
| `NREL_EFS_DataProcessing/` | Aggregates NREL EFS hourly load profiles to annual TWh per scenario |
| `EFS/result/` | The aggregated NREL EFS annual totals |
| `trajectory/` | Full and representative forecast trajectories (national and data center), plus data center ranges in 2025, 2028 and 2030 |
| `range_plot/` | Low / central / high range per institution in benchmark years |
| `heatmap/` | Pairwise difference heatmaps between institutions and within each institution's scenarios |
| `ranking_tables/` | Forecast-level and CAGR rankings (CSV and Excel) |
| `dc_institution.py`, `national_institution.py` | Per-institution appendix figures (`appendix_*_trends/`) |
| `connect.py` | Checks that `DC_FORECAST_DB_URL` reaches the database |
| `requirements.txt` | Python dependencies |
| `report/` | Final report (PDF) |

## Reproducing the results

Requirements: MySQL 8 and Python 3.11+.

```bash
pip install -r requirements.txt
./build_database.sh -u root -p
export DC_FORECAST_DB_URL="mysql+mysqlconnector://USER:PASSWORD@127.0.0.1/us_dc_energy_forecast"
python connect.py
python range_plot/dc_2030_forecast_range.py
```

Every analysis script reads the connection string from `DC_FORECAST_DB_URL`. If it is not set, the scripts use a local `root` login without a password. Each script writes its figures or tables into its own folder, so it can be run from any directory.

The NREL scripts in `NREL_EFS_DataProcessing/` are only needed to regenerate `EFS/result/`. To use them, download the nine `EFSLoadProfile_<Electrification>_<Advancement>.zip` archives from the [EFS Load Profiles data release](https://doi.org/10.7799/1593122). The nine CSVs total about 24 GB and are not included here. Unzip each archive and save its CSV as `EFS/<Electrification>_<Advancement>.csv`, for example `EFS/Reference_Rapid.csv`. Then run the matching script, for example `python NREL_EFS_DataProcessing/Reference_Rapid.py`.

## Notes

- EIA appears twice in the database: the AEO 2025 reference case and the AEO 2026 cases. The benchmark-year analyses use AEO 2026.
- Low / mid / high labels are harmonized across sources (`scenario_standardized`), and each source's original scenario name is kept in `scenario_original`.
- Some sources do not report a value for a benchmark year. In that case the scripts interpolate linearly between the nearest reported years. For example, BP's 2030 and 2035 values lie on the line between its 2023 and 2050 figures. Each growth rate (CAGR) runs from the source's first reported year to the target year.
