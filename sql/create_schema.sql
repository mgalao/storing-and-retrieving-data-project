CREATE DATABASE IF NOT EXISTS TrafficManagement
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE TrafficManagement;

-- DISCUSS ADDING MORE CONSTRAINTS

-- DISCUSS ADDING A USERS TABLE (POINTING TO ADMIN UNITS)
-- Administrative Units Table
CREATE TABLE IF NOT EXISTS administrative_units (
    UNIT_ID INT NOT NULL AUTO_INCREMENT,
    UNIT_NAME VARCHAR(100) NOT NULL,
    UNIT_TYPE ENUM('Municipality', 'Parish') NOT NULL,
    UNIT_PARENT_ID INT DEFAULT NULL,  -- For parishes, references the municipality
    UNIT_CONTACT_EMAIL VARCHAR(100) DEFAULT NULL,
    UNIT_CONTACT_PHONE VARCHAR(15) DEFAULT NULL,
    PRIMARY KEY (UNIT_ID),
    CONSTRAINT fk_unit_parent
        FOREIGN KEY (UNIT_PARENT_ID) REFERENCES administrative_units (UNIT_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Users Table
CREATE TABLE IF NOT EXISTS users (
    USER_ID INT NOT NULL AUTO_INCREMENT,
    UNIT_ID INT NOT NULL,  -- References the administrative unit
    USER_NAME VARCHAR(100) NOT NULL,
    USER_EMAIL VARCHAR(100) NOT NULL UNIQUE,
    USER_ROLE ENUM('Admin', 'Staff', 'Resident') NOT NULL,
    USER_PASSWORD_HASH VARCHAR(255) NOT NULL,
    PRIMARY KEY (USER_ID),
    CONSTRAINT fk_user_unit
        FOREIGN KEY (UNIT_ID) REFERENCES administrative_units (UNIT_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Ratings Table (for municipal services)
CREATE TABLE IF NOT EXISTS ratings (
    RATING_ID INT NOT NULL AUTO_INCREMENT,
    UNIT_ID INT NOT NULL,  -- References the administrative unit (must be mandatory)
    USER_ID INT DEFAULT NULL,  -- References the user who provided the rating (optional)
    RATING_SERVICE_TYPE ENUM('Traffic Monitoring', 'Accident Response', 'System Usability') NOT NULL,  -- Type of service being rated
    RATING INT NOT NULL,  -- Rating scale (1 to 5, where 5 is excellent)
    RATING_COMMENTS TEXT DEFAULT NULL,
    RATING_DATE DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (RATING_ID),
    CONSTRAINT fk_rating_unit
        FOREIGN KEY (UNIT_ID) REFERENCES administrative_units (UNIT_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_rating_user
        FOREIGN KEY (USER_ID) REFERENCES users (USER_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CONSTRAINT chk_rating_value
        CHECK (RATING BETWEEN 1 AND 5)  -- Ensures rating is between 1 and 5
);

-- DISCUSS THE MAX_SPEED_LIMIT EXISTENCE (BECAUSE IT ALREADY EXISTS IN TRAFFIC SENSORS)
-- Roads Table
CREATE TABLE IF NOT EXISTS roads (
    ROAD_ID INT NOT NULL AUTO_INCREMENT,
	UNIT_ID INT NOT NULL,  -- References administrative unit (parish)
    ROAD_NAME VARCHAR(100) NOT NULL,
    ROAD_TYPE ENUM('Street', 'Highway', 'Avenue', 'Boulevard', 'Alley', 'Other') NOT NULL,
    ROAD_LENGTH DECIMAL(6, 2) NOT NULL,  -- Length of the road in kilometers
    ROAD_MAX_SPEED_LIMIT INT NOT NULL,  -- Maximum allowed speed in km/h
    ROAD_CONDITION ENUM('Good', 'Fair', 'Poor', 'Under Construction', 'Closed') NOT NULL,
    PRIMARY KEY (ROAD_ID),
    CONSTRAINT fk_road_unit
        FOREIGN KEY (UNIT_ID) REFERENCES administrative_units (UNIT_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Traffic Sensors Table
CREATE TABLE IF NOT EXISTS traffic_sensors (
    SENSOR_ID INT NOT NULL AUTO_INCREMENT,
    ROAD_ID INT DEFAULT NULL,  -- References the road where the sensor is installed
    SENSOR_INSTALLATION_DATE DATE NOT NULL,
    SENSOR_STATUS ENUM('Active', 'Inactive', 'Under Maintenance') NOT NULL DEFAULT 'Active',
    SENSOR_LATITUDE DECIMAL(9, 6) DEFAULT NULL,  -- Latitude of sensor installation (optional)
    SENSOR_LONGITUDE DECIMAL(9, 6) DEFAULT NULL,  -- Longitude of sensor installation (optional)
    PRIMARY KEY (SENSOR_ID),
    CONSTRAINT fk_sensor_road
        FOREIGN KEY (ROAD_ID) REFERENCES roads (ROAD_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- Traffic Data Table
CREATE TABLE IF NOT EXISTS traffic_data (
    DATA_ID INT NOT NULL AUTO_INCREMENT,
    SENSOR_ID INT NOT NULL,  -- References the sensor generating the data
    DATA_START_DATE DATETIME NOT NULL,  -- Start date/time of the reading period
    DATA_END_DATE DATETIME NOT NULL,  -- End date/time of the reading period
    DATA_VEHICLE_COUNT INT DEFAULT NULL,  -- Number of vehicles counted in the time interval
    DATA_AVERAGE_SPEED DECIMAL(5, 2) DEFAULT NULL,  -- Average speed recorded (km/h) during the interval
    DATA_CONGESTION_LEVEL ENUM('Low', 'Moderate', 'High', 'Severe') DEFAULT NULL,
    PRIMARY KEY (DATA_ID),
    CONSTRAINT fk_traffic_sensor
        FOREIGN KEY (SENSOR_ID) REFERENCES traffic_sensors (SENSOR_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Accidents Table
CREATE TABLE IF NOT EXISTS accidents (
    ACCIDENT_ID INT NOT NULL AUTO_INCREMENT,
    ROAD_ID INT DEFAULT NULL,  -- References the road where the accident occurred
	UNIT_ID INT DEFAULT NULL,  -- References administrative unit (parish)
    ACCIDENT_DATETIME DATETIME NOT NULL,  -- Date and time of the accident
    ACCIDENT_SEVERITY ENUM('Minor', 'Major', 'Critical') NOT NULL,  -- Severity of the accident
	ACCIDENT_LOCATION_TYPE VARCHAR(100) NOT NULL,  -- Specific location within the road (intersection, roundabout, pedestrian crossing, etc)
	ACCIDENT_LATITUDE DECIMAL(9, 6) DEFAULT NULL,  -- Latitude of the location
    ACCIDENT_LONGITUDE DECIMAL(9, 6) DEFAULT NULL,  -- Longitude of the location
    PRIMARY KEY (ACCIDENT_ID),
    CONSTRAINT fk_accident_road
        FOREIGN KEY (ROAD_ID) REFERENCES roads (ROAD_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CONSTRAINT fk_accident_unit
        FOREIGN KEY (UNIT_ID) REFERENCES administrative_units (UNIT_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- Accident Responses Table
CREATE TABLE IF NOT EXISTS accident_responses (
    RESPONSE_ID INT NOT NULL AUTO_INCREMENT,
    ACCIDENT_ID INT NOT NULL,  -- References the accident to which the response is related
	UNIT_ID INT DEFAULT NULL,  -- References administrative unit (parish)
    RESPONSE_START_TIME DATETIME NOT NULL,  -- Time when the emergency call was received
    RESPONSE_END_TIME DATETIME NOT NULL,    -- Time when the help (response unit) arrived at the scene
    RESPONSE_TYPE ENUM('Ambulance', 'Fire Department', 'Police', 'Other') NOT NULL,
    RESPONSE_DISPATCHED_UNITS_COUNT INT NOT NULL,
    PRIMARY KEY (RESPONSE_ID),
    CONSTRAINT fk_emergency_accident
        FOREIGN KEY (ACCIDENT_ID) REFERENCES accidents (ACCIDENT_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_emergency_unit
        FOREIGN KEY (UNIT_ID) REFERENCES administrative_units (UNIT_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- Traffic Violations Table
CREATE TABLE IF NOT EXISTS traffic_violations (
    VIOLATION_ID INT NOT NULL AUTO_INCREMENT,
    ROAD_ID INT NOT NULL,  -- References the road where the violation occurred
    VIOLATION_DATE DATETIME NOT NULL,
    VIOLATION_TYPE VARCHAR(100) NOT NULL,
    VIOLATION_FINE_AMOUNT DECIMAL(8, 2) NOT NULL,
    PRIMARY KEY (VIOLATION_ID),
    CONSTRAINT fk_violation_road
        FOREIGN KEY (ROAD_ID) REFERENCES roads (ROAD_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Logs Table (action tracking)
CREATE TABLE IF NOT EXISTS logs (
    LOG_ID INT NOT NULL AUTO_INCREMENT,
    UNIT_ID INT DEFAULT NULL,  -- References the administrative unit
    LOG_ACTION VARCHAR(255) NOT NULL,
    LOG_TIMESTAMP DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (LOG_ID),
    CONSTRAINT fk_logs_unit
        FOREIGN KEY (UNIT_ID) REFERENCES administrative_units (UNIT_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);