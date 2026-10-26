-- ==============================================================
-- Database: US Data Center Electricity Demand Forecast
-- Author: Jiawei Qi
-- Description:
-- This schema is designed to store and compare multi-source
-- electricity demand forecasts through 2050, focusing on
-- AI-driven data center electricity growth in the United States.
--
-- The database contains four core tables:
-- 1. forecast_metadata        : metadata for total U.S. electricity demand forecasts
-- 2. forecast_values          : yearly values for total U.S. electricity demand forecasts
-- 3. dc_forecast_metadata     : metadata for U.S. data center electricity demand forecasts
-- 4. dc_forecast_values       : yearly values for U.S. data center electricity demand forecasts
-- ==============================================================

DROP DATABASE IF EXISTS us_dc_energy_forecast;
CREATE DATABASE IF NOT EXISTS us_dc_energy_forecast;
USE us_dc_energy_forecast;

-- ===============================================================
-- Table 1: forecast_metadata
-- Description:
-- Store metadata for each total U.S. electricity demand forecast,
-- including source, scenario, region, start and end years,
-- original units and methodological notes.
-- ===============================================================

CREATE TABLE forecast_metadata (
    forecast_id INT AUTO_INCREMENT PRIMARY KEY,
    
    source VARCHAR(255),
    -- short identifier name ('EIA')
    
    organization VARCHAR(255),
    -- full organization name ('Energy Information Administration')
    
    scenario_original VARCHAR(255),
    -- original scenario name from source
    
    scenario_standardized ENUM('low', 'mid', 'high') 
        NOT NULL DEFAULT 'mid',
    -- harmonized scenario for comparison
    
    region_type ENUM('national', 'state', 'ISO')
        NOT NULL DEFAULT 'national',
    
    region VARCHAR(50) 
        NOT NULL DEFAULT 'USA',
    -- geographic scope
    
    year_start INT NOT NULL,
    -- forecast start year
    
    year_end INT NOT NULL,
    -- forecast end year
    
    unit_original VARCHAR(50),
    -- original unit before standardization ('TWh','GW')
    
    description TEXT,
    -- short description of the forecast
    
    notes TEXT,
    -- additional context or methodological notes
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===============================================================
-- Table 2: forecast_values
-- Description:
-- Store yearly total U.S. electricity demand values linked to a
-- forecast. All values must be standardized to TWh unit.
-- ===============================================================

CREATE TABLE forecast_values (
    id INT AUTO_INCREMENT PRIMARY KEY,
    
    forecast_id INT NOT NULL,
    
    year INT NOT NULL CHECK (year BETWEEN 2000 AND 2100),
    
    demand_TWh DECIMAL(10,2) NOT NULL,
    -- total U.S. electricity demand standardized to TWh unit
    
    FOREIGN KEY (forecast_id)
        REFERENCES forecast_metadata(forecast_id)
        ON DELETE CASCADE,
        
    UNIQUE (forecast_id, year)
);

-- ===============================================================
-- Table 3: dc_forecast_metadata
-- Description:
-- Store metadata for each U.S. data center electricity demand
-- forecast, including source, scenario, region, start and end years,
-- original units and methodological notes.
-- ===============================================================

CREATE TABLE dc_forecast_metadata (
    dc_forecast_id INT AUTO_INCREMENT PRIMARY KEY,
    
    source VARCHAR(255),
    -- short identifier name ('LBNL', 'IEA', 'EPRI')
    
    organization VARCHAR(255),
    -- full organization name ('Lawrence Berkeley National Laboratory')
    
    scenario_original VARCHAR(255),
    -- original scenario name from source
    
    scenario_standardized ENUM('low', 'mid', 'high') 
        NOT NULL DEFAULT 'mid',
    -- harmonized scenario for comparison
    
    region_type ENUM('national', 'state', 'ISO')
        NOT NULL DEFAULT 'national',
    
    region VARCHAR(50) 
        NOT NULL DEFAULT 'USA',
    -- geographic scope
    
    year_start INT NOT NULL,
    -- forecast start year
    
    year_end INT NOT NULL,
    -- forecast end year
    
    unit_original VARCHAR(50),
    -- original unit before standardization ('TWh', 'GWh', '%')
    
    description TEXT,
    -- short description of the data center electricity forecast
    
    notes TEXT,
    -- additional context or methodological notes
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===============================================================
-- Table 4: dc_forecast_values
-- Description:
-- Store yearly U.S. data center electricity demand values linked
-- to a data center forecast.
-- Electricity demand values should be standardized to TWh.
-- ===============================================================

CREATE TABLE dc_forecast_values (
    id INT AUTO_INCREMENT PRIMARY KEY,
    
    dc_forecast_id INT NOT NULL,
    
    year INT NOT NULL CHECK (year BETWEEN 2000 AND 2100),
    
    demand_TWh DECIMAL(10,2),
    -- U.S. data center electricity demand standardized to TWh unit
    
    share_percent DECIMAL(6,2),
    -- data center electricity demand as percentage of total U.S. electricity use
    
    FOREIGN KEY (dc_forecast_id)
        REFERENCES dc_forecast_metadata(dc_forecast_id)
        ON DELETE CASCADE,
        
    UNIQUE (dc_forecast_id, year)
);

-- ===============================================================
-- Optional Indexes
-- ===============================================================

CREATE INDEX idx_year ON forecast_values(year);
CREATE INDEX idx_forecast_id ON forecast_values(forecast_id);
CREATE INDEX idx_source ON forecast_metadata(source);

CREATE INDEX idx_dc_year ON dc_forecast_values(year);
CREATE INDEX idx_dc_forecast_id ON dc_forecast_values(dc_forecast_id);
CREATE INDEX idx_dc_source ON dc_forecast_metadata(source);