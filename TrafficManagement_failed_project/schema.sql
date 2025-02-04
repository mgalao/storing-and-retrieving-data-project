CREATE DATABASE IF NOT EXISTS TrafficManagement
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE TrafficManagement;

-- Subscribed Municipalities Table
CREATE TABLE IF NOT EXISTS subscribed_municipalities (
    MUNICIPALITY_ID INT NOT NULL,
    MUNICIPALITY_NAME VARCHAR(100) NOT NULL,
    MUNICIPALITY_CONTACT_EMAIL VARCHAR(100) DEFAULT NULL,
    MUNICIPALITY_CONTACT_PHONE VARCHAR(15) DEFAULT NULL,
    PRIMARY KEY (MUNICIPALITY_ID)
);

-- Subscriptions Table
CREATE TABLE IF NOT EXISTS subscriptions (
    SUBSCRIPTION_ID INT NOT NULL AUTO_INCREMENT,
	SUBSCRIPTION_PRICE DECIMAL(10, 2) NOT NULL,
    SUBSCRIPTION_START_DATE DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    SUBSCRIPTION_END_DATE DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    MUNICIPALITY_ID INT NOT NULL,  -- References the municipality associated with the subscription
    PRIMARY KEY (SUBSCRIPTION_ID),
    CONSTRAINT fk_subscription_municipality
        FOREIGN KEY (MUNICIPALITY_ID) REFERENCES subscribed_municipalities (MUNICIPALITY_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Services Table
CREATE TABLE IF NOT EXISTS services (
    SERVICE_ID INT NOT NULL,
    SERVICE_CATEGORY ENUM(
        'Database',
        'Documentation',
        'Customer Support',
        'Consultancy',
        'Training'
    ) NOT NULL,
	SERVICE_PRICE DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (SERVICE_ID)
);

-- Junction Table: Subscription Services Table
CREATE TABLE IF NOT EXISTS subscription_services (
    SUBSCRIPTION_ID INT NOT NULL,  -- References the subscription
    SERVICE_ID INT NOT NULL,  -- References the service
    PRIMARY KEY (SUBSCRIPTION_ID, SERVICE_ID),
    CONSTRAINT fk_subscription
        FOREIGN KEY (SUBSCRIPTION_ID) REFERENCES subscriptions (SUBSCRIPTION_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_service
        FOREIGN KEY (SERVICE_ID) REFERENCES services (SERVICE_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Ratings Table
CREATE TABLE IF NOT EXISTS ratings (
    RATING_ID INT NOT NULL AUTO_INCREMENT,
    RATING INT NOT NULL,  -- Rating (1 to 5, where 5 is excellent)
    RATING_COMMENTS TEXT DEFAULT NULL,
    RATING_DATE DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    MUNICIPALITY_ID INT NOT NULL,  -- References the municipality/parish as the customer
    SERVICE_ID INT NOT NULL,  -- References the service being rated
    PRIMARY KEY (RATING_ID),
    CONSTRAINT fk_rating_municipality
        FOREIGN KEY (MUNICIPALITY_ID) REFERENCES subscribed_municipalities (MUNICIPALITY_ID)
        ON DELETE RESTRICT  
        ON UPDATE CASCADE,
    CONSTRAINT fk_rating_service
        FOREIGN KEY (SERVICE_ID) REFERENCES services (SERVICE_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_rating_value
        CHECK (RATING BETWEEN 1 AND 5)  -- Ensures rating is between 1 and 5
);

-- Parishes Table
CREATE TABLE IF NOT EXISTS parishes (
    PARISH_ID INT NOT NULL,
    PARISH_NAME VARCHAR(100) NOT NULL,
    PARISH_CONTACT_EMAIL VARCHAR(100) DEFAULT NULL,
    PARISH_CONTACT_PHONE VARCHAR(15) DEFAULT NULL,
    MUNICIPALITY_ID INT NOT NULL,  -- References the municipality to which the parish belongs
    PRIMARY KEY (PARISH_ID),
    CONSTRAINT fk_parish_municipality
        FOREIGN KEY (MUNICIPALITY_ID) REFERENCES subscribed_municipalities (MUNICIPALITY_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Roads Table
CREATE TABLE IF NOT EXISTS roads (
    ROAD_ID INT NOT NULL,
    ROAD_NAME VARCHAR(100) NOT NULL,
    ROAD_TYPE ENUM(
        'Freeway',
        'Ramp',
        'Major Highway',
        'Minor Highway',
        'Primary Street',
        'Secondary Street'
    ) NOT NULL,
    ROAD_LENGTH DECIMAL(6, 2) NOT NULL,  -- Length of the road in kilometers
    ROAD_MAX_SPEED_LIMIT INT NOT NULL,  -- Maximum allowed speed in km/h
    ROAD_MIN_SPEED_LIMIT INT DEFAULT NULL,  -- Minimum allowed speed in km/h
    ROAD_CONDITION ENUM(
        'Good',
        'Fair',
        'Poor',
        'Under Construction',
        'Closed'
    ) NOT NULL,
    PRIMARY KEY (ROAD_ID),    
	CONSTRAINT chk_speed_limit
        CHECK (ROAD_MIN_SPEED_LIMIT <= ROAD_MAX_SPEED_LIMIT)  -- Ensures minimum speed limit is lower or equal to max speed limit
);

-- Junction Table: Parish Roads Table
CREATE TABLE IF NOT EXISTS parish_roads (
    PARISH_ID INT NOT NULL,  -- References the parish
    ROAD_ID INT NOT NULL,  -- References the road
    PRIMARY KEY (PARISH_ID, ROAD_ID),
    CONSTRAINT fk_parish
        FOREIGN KEY (PARISH_ID) REFERENCES parishes (PARISH_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_road
        FOREIGN KEY (ROAD_ID) REFERENCES roads (ROAD_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Accidents Table
CREATE TABLE IF NOT EXISTS accidents (
    ACCIDENT_ID INT NOT NULL AUTO_INCREMENT,
    ACCIDENT_DATE DATETIME NOT NULL,  -- Date and time of the accident
    ACCIDENT_SEVERITY ENUM(
        'Minor', -- Low damage, no injuries or minor injuries, no serious vehicle damage
        'Major', -- Significant damage, potential injuries, but not life-threatening
        'Critical' -- Life-threatening injuries, fatalities, or very severe damage
    ) NOT NULL,  -- Severity of the accident
	ACCIDENT_LATITUDE DECIMAL(9, 6) DEFAULT NULL,  -- Latitude of the location
    ACCIDENT_LONGITUDE DECIMAL(9, 6) DEFAULT NULL,  -- Longitude of the location
    ROAD_ID INT NOT NULL,  -- References the road where the accident occurred
    PRIMARY KEY (ACCIDENT_ID),
    CONSTRAINT fk_accident_road
        FOREIGN KEY (ROAD_ID) REFERENCES roads (ROAD_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Accident Responses Table
CREATE TABLE IF NOT EXISTS accident_responses (
    RESPONSE_ID INT NOT NULL AUTO_INCREMENT,
    RESPONSE_START_TIME DATETIME NOT NULL,  -- Time when the emergency call was received
    RESPONSE_END_TIME DATETIME NOT NULL,  -- Time when the help (response unit) arrived at the scene
    RESPONSE_TYPE ENUM(
        'Ambulance',
        'Fire Department',
        'Police',
        'Other'
    ) NOT NULL,
    RESPONSE_DISPATCHED_UNITS_COUNT INT NOT NULL,
    ACCIDENT_ID INT NOT NULL,  -- References the accident to which the response is related
	PARISH_ID INT NOT NULL,  -- References parish where the accident occurred
    PRIMARY KEY (RESPONSE_ID),
    CONSTRAINT fk_emergency_accident
        FOREIGN KEY (ACCIDENT_ID) REFERENCES accidents (ACCIDENT_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_emergency_parish
        FOREIGN KEY (PARISH_ID) REFERENCES parishes (PARISH_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_response_time
        CHECK (RESPONSE_START_TIME < RESPONSE_END_TIME)  -- Ensures start time is before end time
);

-- Traffic Sensors Table
CREATE TABLE IF NOT EXISTS traffic_sensors (
    SENSOR_ID INT NOT NULL,
    SENSOR_INSTALLATION_DATE DATE NOT NULL,
    SENSOR_STATUS ENUM(
        'Active',
        'Inactive',
        'Under Maintenance'
    ) NOT NULL DEFAULT 'Active',
    SENSOR_LATITUDE DECIMAL(9, 6) DEFAULT NULL,  -- Latitude of sensor installation
    SENSOR_LONGITUDE DECIMAL(9, 6) DEFAULT NULL,  -- Longitude of sensor installation
    ROAD_ID INT NOT NULL,  -- References the road where the sensor is installed
    PRIMARY KEY (SENSOR_ID),
    CONSTRAINT fk_sensor_road
        FOREIGN KEY (ROAD_ID) REFERENCES roads (ROAD_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Traffic Data Table
CREATE TABLE IF NOT EXISTS traffic_data (
    DATA_ID INT NOT NULL AUTO_INCREMENT,
    DATA_START_DATE DATETIME NOT NULL,  -- Start date/time of the reading period
    DATA_END_DATE DATETIME NOT NULL,  -- End date/time of the reading period
    DATA_VEHICLE_COUNT INT DEFAULT NULL,  -- Number of vehicles counted in the time interval
    DATA_AVERAGE_SPEED DECIMAL(5, 2) DEFAULT NULL,  -- Average speed recorded (km/h) during the interval
    SENSOR_ID INT NOT NULL,  -- References the sensor generating the data
    PRIMARY KEY (DATA_ID),
    CONSTRAINT fk_traffic_sensor
        FOREIGN KEY (SENSOR_ID) REFERENCES traffic_sensors (SENSOR_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_data_interval
        CHECK (DATA_START_DATE < DATA_END_DATE),  -- Ensures start date is before end date
    CONSTRAINT chk_data_vehicle_count
        CHECK (DATA_VEHICLE_COUNT >= 0),  -- Ensures vehicle count is non-negative
    CONSTRAINT chk_data_average_speed
        CHECK (DATA_AVERAGE_SPEED >= 0)  -- Ensures average speed is non-negative
);

-- Traffic Violations Table
CREATE TABLE IF NOT EXISTS traffic_violations (
    VIOLATION_ID INT NOT NULL AUTO_INCREMENT,
    VIOLATION_DATE DATETIME NOT NULL,
    VIOLATION_SEVERITY ENUM(
        'Minor',
        'Moderate',
        'Severe'
    ) NOT NULL,
    VIOLATION_FINE_AMOUNT DECIMAL(8, 2) DEFAULT NULL,
    ROAD_ID INT NOT NULL,  -- References the road where the violation occurred
    PRIMARY KEY (VIOLATION_ID),
    CONSTRAINT fk_violation_road
        FOREIGN KEY (ROAD_ID) REFERENCES roads (ROAD_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Junction Table: Sensor Violation Table
CREATE TABLE IF NOT EXISTS sensor_violation (
    SENSOR_ID INT NOT NULL,  -- References the traffic sensor
    VIOLATION_ID INT NOT NULL,  -- References the traffic violation
    PRIMARY KEY (SENSOR_ID, VIOLATION_ID),
    CONSTRAINT fk_sensor
        FOREIGN KEY (SENSOR_ID) REFERENCES traffic_sensors (SENSOR_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_violation
        FOREIGN KEY (VIOLATION_ID) REFERENCES traffic_violations (VIOLATION_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Logs Table
CREATE TABLE IF NOT EXISTS logs (
    LOG_ID INT NOT NULL AUTO_INCREMENT,
    LOG_EVENT_TYPE ENUM(
        'Contact Update',
        'Service Price Update',
        'Road Speed Limit Update',
        'Road Condition Update',
        'Traffic Sensor Status Update'
    ) NOT NULL,
    LOG_EVENT_DESCRIPTION TEXT NOT NULL,
    LOG_CREATION_DATE DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (LOG_ID)
);