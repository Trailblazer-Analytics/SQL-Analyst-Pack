-- =====================================================
-- IoT Time Series Sample Database
-- =====================================================
-- Purpose: Time series analysis and monitoring scenarios:
-- - Sensor data analysis and trend detection
-- - Real-time monitoring and alerting
-- - Predictive maintenance analytics
-- - Performance optimization tracking
-- =====================================================

-- Create database schema for IoT time series data

-- Device types table: Categories of IoT devices
CREATE TABLE device_types (
    device_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    description TEXT,
    expected_lifespan_days INTEGER,
    maintenance_interval_days INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Devices table: Individual IoT devices and sensors
CREATE TABLE devices (
    device_id SERIAL PRIMARY KEY,
    device_type_id INTEGER REFERENCES device_types(device_type_id),
    device_name VARCHAR(255) NOT NULL,
    serial_number VARCHAR(100) UNIQUE NOT NULL,
    location_building VARCHAR(100),
    location_floor INTEGER,
    location_room VARCHAR(50),
    location_coordinates POINT, -- Geographic coordinates if applicable
    installation_date DATE NOT NULL,
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    device_status VARCHAR(20) CHECK (device_status IN ('active', 'inactive', 'maintenance', 'error', 'offline')),
    firmware_version VARCHAR(50),
    hardware_version VARCHAR(50),
    network_address INET,
    sampling_interval_seconds INTEGER DEFAULT 60,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sensor readings table: Time series data from devices
CREATE TABLE sensor_readings (
    reading_id BIGSERIAL PRIMARY KEY,
    device_id INTEGER REFERENCES devices(device_id),
    timestamp TIMESTAMP NOT NULL,
    temperature DECIMAL(8,3), -- Celsius
    humidity DECIMAL(5,2), -- Percentage
    pressure DECIMAL(10,2), -- kPa
    light_level DECIMAL(10,2), -- Lux
    noise_level DECIMAL(6,2), -- dB
    vibration_x DECIMAL(8,4), -- m/s²
    vibration_y DECIMAL(8,4), -- m/s²
    vibration_z DECIMAL(8,4), -- m/s²
    voltage DECIMAL(6,3), -- Volts
    current DECIMAL(8,4), -- Amperes
    power_consumption DECIMAL(10,3), -- Watts
    cpu_usage DECIMAL(5,2), -- Percentage
    memory_usage DECIMAL(5,2), -- Percentage
    disk_usage DECIMAL(5,2), -- Percentage
    network_latency DECIMAL(8,2), -- Milliseconds
    signal_strength INTEGER, -- dBm
    battery_level DECIMAL(5,2), -- Percentage
    error_count INTEGER DEFAULT 0,
    warning_count INTEGER DEFAULT 0,
    quality_score DECIMAL(5,2) CHECK (quality_score BETWEEN 0 AND 100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Device alerts table: Automated alerts and notifications
CREATE TABLE device_alerts (
    alert_id SERIAL PRIMARY KEY,
    device_id INTEGER REFERENCES devices(device_id),
    alert_type VARCHAR(50) NOT NULL,
    alert_level VARCHAR(20) CHECK (alert_level IN ('info', 'warning', 'error', 'critical')),
    alert_message TEXT NOT NULL,
    threshold_value DECIMAL(15,4),
    actual_value DECIMAL(15,4),
    alert_timestamp TIMESTAMP NOT NULL,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by VARCHAR(100),
    acknowledged_at TIMESTAMP,
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP,
    resolution_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Maintenance logs table: Device maintenance history
CREATE TABLE maintenance_logs (
    maintenance_id SERIAL PRIMARY KEY,
    device_id INTEGER REFERENCES devices(device_id),
    maintenance_type VARCHAR(50) CHECK (maintenance_type IN ('preventive', 'corrective', 'emergency', 'upgrade')),
    maintenance_date DATE NOT NULL,
    performed_by VARCHAR(100),
    description TEXT,
    parts_replaced TEXT,
    cost DECIMAL(10,2),
    downtime_minutes INTEGER,
    next_maintenance_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- Insert Sample Data
-- =====================================================

-- Insert device types
INSERT INTO device_types (type_name, category, manufacturer, model, description, expected_lifespan_days, maintenance_interval_days)
VALUES 
    ('Temperature Sensor', 'Environmental', 'SensorTech', 'ST-T200', 'High-precision temperature monitoring', 1825, 90),
    ('Humidity Sensor', 'Environmental', 'SensorTech', 'ST-H150', 'Relative humidity measurement', 1825, 90),
    ('Pressure Sensor', 'Industrial', 'IndustrialSys', 'IS-P500', 'Industrial pressure monitoring', 2190, 60),
    ('Vibration Monitor', 'Mechanical', 'VibeTech', 'VT-VM300', 'Machine vibration analysis', 1460, 30),
    ('Power Monitor', 'Electrical', 'PowerSys', 'PS-PM100', 'Electrical power consumption tracking', 2555, 180),
    ('Air Quality Sensor', 'Environmental', 'AirTech', 'AT-AQ250', 'Indoor air quality monitoring', 1095, 60),
    ('Light Sensor', 'Environmental', 'LightSys', 'LS-L100', 'Ambient light level detection', 2190, 120),
    ('Sound Monitor', 'Environmental', 'AudioTech', 'AU-SM200', 'Noise level monitoring', 1460, 90),
    ('Network Monitor', 'IT', 'NetSys', 'NS-NM400', 'Network performance monitoring', 1825, 30),
    ('Smart Thermostat', 'HVAC', 'ClimateControl', 'CC-ST500', 'Intelligent temperature control', 2920, 180);

-- Insert devices (200 devices across different locations)
INSERT INTO devices (device_type_id, device_name, serial_number, location_building, location_floor, location_room, 
                    installation_date, device_status, firmware_version, sampling_interval_seconds)
SELECT 
    (i % 10) + 1,
    'Device_' || LPAD(i::text, 3, '0'),
    'SN' || LPAD(i::text, 8, '0'),
    CASE (i % 5)
        WHEN 0 THEN 'Building A'
        WHEN 1 THEN 'Building B'
        WHEN 2 THEN 'Building C'
        WHEN 3 THEN 'Warehouse'
        ELSE 'Data Center'
    END,
    ((i % 10) + 1),
    'Room ' || LPAD(((i % 20) + 1)::text, 3, '0'),
    CURRENT_DATE - (i % 1000), -- Installed over past ~3 years
    CASE 
        WHEN i % 50 = 0 THEN 'maintenance'
        WHEN i % 100 = 0 THEN 'offline'
        WHEN i % 200 = 0 THEN 'error'
        ELSE 'active'
    END,
    '2.' || (i % 5) || '.' || (i % 10),
    CASE (i % 4)
        WHEN 0 THEN 30  -- Every 30 seconds
        WHEN 1 THEN 60  -- Every minute
        WHEN 2 THEN 300 -- Every 5 minutes
        ELSE 900        -- Every 15 minutes
    END
FROM generate_series(1, 200) AS i;

-- Insert sensor readings (1 million readings - approximately 6 months of data)
-- This creates realistic time series data with patterns and anomalies
INSERT INTO sensor_readings (device_id, timestamp, temperature, humidity, pressure, light_level, noise_level,
                           vibration_x, vibration_y, vibration_z, voltage, current, power_consumption,
                           cpu_usage, memory_usage, battery_level, quality_score)
SELECT 
    device_id,
    reading_time,
    -- Temperature: Realistic patterns with daily/seasonal variation
    CASE dt.type_name
        WHEN 'Temperature Sensor' THEN 
            20 + 5 * SIN(EXTRACT(HOUR FROM reading_time) * PI() / 12) + -- Daily pattern
            2 * SIN(EXTRACT(DOY FROM reading_time) * 2 * PI() / 365) + -- Seasonal pattern
            (RANDOM() - 0.5) * 3 -- Random variation
        ELSE 18 + (RANDOM() * 10)
    END,
    -- Humidity: Inversely related to temperature with noise
    CASE dt.type_name
        WHEN 'Humidity Sensor' THEN 
            70 - 2 * SIN(EXTRACT(HOUR FROM reading_time) * PI() / 12) + 
            (RANDOM() - 0.5) * 20
        ELSE 40 + (RANDOM() * 40)
    END,
    -- Pressure: Stable with weather-like variations
    101.3 + SIN(EXTRACT(EPOCH FROM reading_time) / 86400) * 2 + (RANDOM() - 0.5) * 1,
    -- Light level: Strong daily pattern
    CASE 
        WHEN EXTRACT(HOUR FROM reading_time) BETWEEN 6 AND 18 THEN
            1000 * SIN((EXTRACT(HOUR FROM reading_time) - 6) * PI() / 12) + (RANDOM() * 200)
        ELSE (RANDOM() * 50)
    END,
    -- Noise level: Business hours pattern
    CASE 
        WHEN EXTRACT(HOUR FROM reading_time) BETWEEN 8 AND 17 AND EXTRACT(DOW FROM reading_time) BETWEEN 1 AND 5 THEN
            45 + (RANDOM() * 15)
        ELSE 35 + (RANDOM() * 10)
    END,
    -- Vibration (industrial equipment patterns)
    (RANDOM() - 0.5) * 0.1 + CASE WHEN RANDOM() < 0.01 THEN (RANDOM() * 2) ELSE 0 END, -- X-axis
    (RANDOM() - 0.5) * 0.1 + CASE WHEN RANDOM() < 0.01 THEN (RANDOM() * 2) ELSE 0 END, -- Y-axis  
    (RANDOM() - 0.5) * 0.05 + CASE WHEN RANDOM() < 0.01 THEN (RANDOM() * 1) ELSE 0 END, -- Z-axis
    -- Electrical measurements
    220 + (RANDOM() - 0.5) * 20, -- Voltage
    5 + (RANDOM() * 10), -- Current
    -- Power consumption: Business hours pattern
    CASE 
        WHEN EXTRACT(HOUR FROM reading_time) BETWEEN 8 AND 17 THEN
            800 + (RANDOM() * 400)
        ELSE 200 + (RANDOM() * 200)
    END,
    -- System metrics
    20 + (RANDOM() * 60), -- CPU usage
    30 + (RANDOM() * 50), -- Memory usage
    -- Battery level: Gradual decline with charging cycles
    GREATEST(10, 100 - (EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - reading_time)) / 86400 * 0.5) + 
             CASE WHEN RANDOM() < 0.1 THEN 50 ELSE 0 END), -- Occasional charging
    -- Quality score: Generally good with occasional issues
    CASE 
        WHEN RANDOM() < 0.05 THEN 50 + (RANDOM() * 30) -- 5% poor quality
        ELSE 85 + (RANDOM() * 15) -- 95% good quality
    END
FROM (
    SELECT 
        d.device_id,
        dt.type_name,
        -- Generate timestamps: 6 months of data at device-specific intervals
        CURRENT_TIMESTAMP - INTERVAL '180 days' + 
        (i * d.sampling_interval_seconds * INTERVAL '1 second') as reading_time
    FROM devices d
    JOIN device_types dt ON d.device_type_id = dt.device_type_id
    CROSS JOIN generate_series(0, (180 * 24 * 3600 / d.sampling_interval_seconds)::integer) AS i
    WHERE d.device_status = 'active'
    AND i <= 5000 -- Limit to control data volume per device
) AS time_series
WHERE reading_time <= CURRENT_TIMESTAMP
ORDER BY device_id, reading_time;

-- Insert device alerts based on sensor data anomalies
INSERT INTO device_alerts (device_id, alert_type, alert_level, alert_message, threshold_value, actual_value, alert_timestamp)
SELECT 
    sr.device_id,
    CASE 
        WHEN sr.temperature > 35 THEN 'high_temperature'
        WHEN sr.humidity > 90 THEN 'high_humidity'
        WHEN sr.vibration_x > 1.0 OR sr.vibration_y > 1.0 OR sr.vibration_z > 0.5 THEN 'excessive_vibration'
        WHEN sr.battery_level < 20 THEN 'low_battery'
        WHEN sr.quality_score < 60 THEN 'poor_data_quality'
        ELSE 'system_warning'
    END,
    CASE 
        WHEN sr.temperature > 40 OR sr.vibration_x > 2.0 OR sr.battery_level < 10 THEN 'critical'
        WHEN sr.temperature > 35 OR sr.humidity > 90 OR sr.vibration_x > 1.0 OR sr.battery_level < 20 THEN 'error'
        WHEN sr.quality_score < 70 THEN 'warning'
        ELSE 'info'
    END,
    CASE 
        WHEN sr.temperature > 35 THEN 'Temperature exceeded safe operating range'
        WHEN sr.humidity > 90 THEN 'Humidity level too high for equipment'
        WHEN sr.vibration_x > 1.0 OR sr.vibration_y > 1.0 OR sr.vibration_z > 0.5 THEN 'Abnormal vibration detected'
        WHEN sr.battery_level < 20 THEN 'Device battery level critically low'
        WHEN sr.quality_score < 60 THEN 'Data quality below acceptable threshold'
        ELSE 'System monitoring alert'
    END,
    CASE 
        WHEN sr.temperature > 35 THEN 35.0
        WHEN sr.humidity > 90 THEN 90.0
        WHEN sr.vibration_x > 1.0 THEN 1.0
        WHEN sr.vibration_y > 1.0 THEN 1.0
        WHEN sr.vibration_z > 0.5 THEN 0.5
        WHEN sr.battery_level < 20 THEN 20.0
        WHEN sr.quality_score < 60 THEN 60.0
        ELSE 0.0
    END,
    CASE 
        WHEN sr.temperature > 35 THEN sr.temperature
        WHEN sr.humidity > 90 THEN sr.humidity
        WHEN sr.vibration_x > 1.0 THEN sr.vibration_x
        WHEN sr.vibration_y > 1.0 THEN sr.vibration_y
        WHEN sr.vibration_z > 0.5 THEN sr.vibration_z
        WHEN sr.battery_level < 20 THEN sr.battery_level
        WHEN sr.quality_score < 60 THEN sr.quality_score
        ELSE 0.0
    END,
    sr.timestamp
FROM sensor_readings sr
WHERE sr.temperature > 35 
   OR sr.humidity > 90 
   OR sr.vibration_x > 1.0 
   OR sr.vibration_y > 1.0 
   OR sr.vibration_z > 0.5
   OR sr.battery_level < 20 
   OR sr.quality_score < 60
   AND RANDOM() < 0.3; -- Sample only 30% of qualifying readings to avoid too many alerts

-- Update some alerts as acknowledged and resolved
UPDATE device_alerts 
SET acknowledged = TRUE, 
    acknowledged_by = 'maintenance_team',
    acknowledged_at = alert_timestamp + INTERVAL '30 minutes'
WHERE RANDOM() < 0.7;

UPDATE device_alerts 
SET resolved = TRUE,
    resolved_at = acknowledged_at + INTERVAL '2 hours',
    resolution_notes = 'Issue resolved through maintenance procedure'
WHERE acknowledged = TRUE AND RANDOM() < 0.8;

-- Insert maintenance logs
INSERT INTO maintenance_logs (device_id, maintenance_type, maintenance_date, performed_by, description, cost, downtime_minutes, next_maintenance_date)
SELECT 
    d.device_id,
    CASE (i % 4)
        WHEN 0 THEN 'preventive'
        WHEN 1 THEN 'corrective'
        WHEN 2 THEN 'emergency'
        ELSE 'upgrade'
    END,
    CURRENT_DATE - (i % 365),
    CASE (i % 3)
        WHEN 0 THEN 'technician_a'
        WHEN 1 THEN 'technician_b'
        ELSE 'maintenance_team'
    END,
    CASE (i % 4)
        WHEN 0 THEN 'Routine maintenance and calibration'
        WHEN 1 THEN 'Repair of faulty sensor component'
        WHEN 2 THEN 'Emergency response to critical alert'
        ELSE 'Firmware upgrade and configuration update'
    END,
    ROUND((RANDOM() * 500 + 50)::numeric, 2),
    CASE (i % 4)
        WHEN 0 THEN 30  -- Preventive
        WHEN 1 THEN 120 -- Corrective
        WHEN 2 THEN 60  -- Emergency
        ELSE 90         -- Upgrade
    END,
    CURRENT_DATE + ((90 + (i % 180)) || ' days')::interval
FROM devices d
CROSS JOIN generate_series(1, 3) AS i -- 3 maintenance records per device
WHERE RANDOM() < 0.6; -- Not all devices have maintenance history

-- =====================================================
-- Create useful indexes for time series performance
-- =====================================================

CREATE INDEX idx_devices_status ON devices(device_status);
CREATE INDEX idx_devices_type ON devices(device_type_id);
CREATE INDEX idx_devices_location ON devices(location_building, location_floor);
CREATE INDEX idx_sensor_readings_device_time ON sensor_readings(device_id, timestamp);
CREATE INDEX idx_sensor_readings_timestamp ON sensor_readings(timestamp);
CREATE INDEX idx_sensor_readings_temperature ON sensor_readings(temperature);
CREATE INDEX idx_sensor_readings_quality ON sensor_readings(quality_score);
CREATE INDEX idx_device_alerts_device_time ON device_alerts(device_id, alert_timestamp);
CREATE INDEX idx_device_alerts_level ON device_alerts(alert_level);
CREATE INDEX idx_device_alerts_status ON device_alerts(acknowledged, resolved);
CREATE INDEX idx_maintenance_logs_device_date ON maintenance_logs(device_id, maintenance_date);

-- =====================================================
-- Create helpful views for time series analysis
-- =====================================================

-- Device health summary view
CREATE VIEW device_health_summary AS
SELECT 
    d.device_id,
    d.device_name,
    dt.type_name,
    d.location_building,
    d.device_status,
    COUNT(sr.reading_id) as total_readings,
    AVG(sr.quality_score) as avg_quality_score,
    COUNT(da.alert_id) as total_alerts,
    SUM(CASE WHEN da.alert_level = 'critical' THEN 1 ELSE 0 END) as critical_alerts,
    MAX(sr.timestamp) as last_reading_time,
    COUNT(ml.maintenance_id) as maintenance_count,
    MAX(ml.maintenance_date) as last_maintenance_date
FROM devices d
JOIN device_types dt ON d.device_type_id = dt.device_type_id
LEFT JOIN sensor_readings sr ON d.device_id = sr.device_id
LEFT JOIN device_alerts da ON d.device_id = da.device_id
LEFT JOIN maintenance_logs ml ON d.device_id = ml.device_id
GROUP BY d.device_id, d.device_name, dt.type_name, d.location_building, d.device_status;

-- Hourly aggregated sensor data view
CREATE VIEW hourly_sensor_aggregates AS
SELECT 
    device_id,
    DATE_TRUNC('hour', timestamp) as hour,
    COUNT(*) as reading_count,
    AVG(temperature) as avg_temperature,
    MIN(temperature) as min_temperature,
    MAX(temperature) as max_temperature,
    AVG(humidity) as avg_humidity,
    AVG(pressure) as avg_pressure,
    AVG(power_consumption) as avg_power_consumption,
    AVG(quality_score) as avg_quality_score,
    COUNT(CASE WHEN quality_score < 70 THEN 1 END) as poor_quality_readings
FROM sensor_readings
GROUP BY device_id, DATE_TRUNC('hour', timestamp);

-- Alert frequency analysis view
CREATE VIEW alert_frequency_analysis AS
SELECT 
    d.device_id,
    d.device_name,
    dt.type_name,
    DATE_TRUNC('day', da.alert_timestamp) as alert_date,
    da.alert_type,
    da.alert_level,
    COUNT(*) as alert_count,
    AVG(da.actual_value) as avg_alert_value,
    COUNT(CASE WHEN da.resolved THEN 1 END) as resolved_count
FROM devices d
JOIN device_types dt ON d.device_type_id = dt.device_type_id
JOIN device_alerts da ON d.device_id = da.device_id
GROUP BY d.device_id, d.device_name, dt.type_name, DATE_TRUNC('day', da.alert_timestamp), da.alert_type, da.alert_level;

-- =====================================================
-- Example Time Series Analytics Queries
-- =====================================================

-- Example 1: Trend analysis for temperature over time
/*
SELECT 
    DATE_TRUNC('hour', timestamp) as hour,
    AVG(temperature) as avg_temp,
    MIN(temperature) as min_temp,
    MAX(temperature) as max_temp,
    STDDEV(temperature) as temp_stddev
FROM sensor_readings
WHERE device_id = 1
  AND timestamp >= CURRENT_TIMESTAMP - INTERVAL '7 days'
GROUP BY DATE_TRUNC('hour', timestamp)
ORDER BY hour;
*/

-- Example 2: Anomaly detection using statistical thresholds
/*
WITH stats AS (
    SELECT 
        device_id,
        AVG(temperature) as mean_temp,
        STDDEV(temperature) as stddev_temp
    FROM sensor_readings
    WHERE timestamp >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY device_id
)
SELECT 
    sr.device_id,
    sr.timestamp,
    sr.temperature,
    s.mean_temp,
    ABS(sr.temperature - s.mean_temp) / s.stddev_temp as z_score
FROM sensor_readings sr
JOIN stats s ON sr.device_id = s.device_id
WHERE sr.timestamp >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
  AND ABS(sr.temperature - s.mean_temp) / s.stddev_temp > 2
ORDER BY z_score DESC;
*/

-- Example 3: Device performance correlation analysis
/*
SELECT 
    sr1.device_id as device1,
    sr2.device_id as device2,
    CORR(sr1.temperature, sr2.temperature) as temp_correlation,
    CORR(sr1.power_consumption, sr2.power_consumption) as power_correlation
FROM sensor_readings sr1
JOIN sensor_readings sr2 ON sr1.timestamp = sr2.timestamp
WHERE sr1.device_id < sr2.device_id
  AND sr1.timestamp >= CURRENT_TIMESTAMP - INTERVAL '7 days'
GROUP BY sr1.device_id, sr2.device_id
HAVING COUNT(*) > 100
ORDER BY temp_correlation DESC;
*/
