/**
 * @description Trigger for Event object to handle calendar validation
 * Prevents double-booking and weekend meeting scheduling
 * @author Temitayo Oluwalade
 * @date 2024
 */
trigger EventValidationTrigger on Event (before insert, before update) {
    
    // Delegate to handler class for better organization and testability
    EventValidationHandler handler = new EventValidationHandler();
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
