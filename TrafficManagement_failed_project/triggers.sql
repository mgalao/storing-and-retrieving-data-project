DELIMITER $$

CREATE TRIGGER log_new_rating
AFTER INSERT ON ratings
FOR EACH ROW
BEGIN
    -- Insert a new log entry into the system_logs table
    INSERT INTO system_logs (EVENT_TYPE, EVENT_DESCRIPTION, RELATED_ENTITY_ID)
    VALUES (
        'New Rating',
        CONCAT('A new rating has been submitted for ', NEW.RATING_PRODUCT, 
               '. Municipality ID: ', NEW.UNIT_ID, 
               '. Rating: ', NEW.RATING, 
               '. Comments: ', IFNULL(NEW.RATING_COMMENTS, 'No comments provided.')
        ),
        NEW.UNIT_ID
    );
END$$

DELIMITER ;