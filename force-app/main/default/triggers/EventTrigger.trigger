trigger EventTrigger on Event (before insert, before update) {
    if (Trigger.isInsert || Trigger.isUpdate) {
        EventTriggerHandler.checkForDuplicateStartTimes(Trigger.new);
    }
}
