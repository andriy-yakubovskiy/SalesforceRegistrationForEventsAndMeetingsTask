trigger EventRegistrationTrigger on Event_Registration__c (before insert, before update, after insert, after update, after delete) {
       
    EventRegistrationTriggerHandler.handleTrigger(Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete, 
                                                  Trigger.isBefore, Trigger.isAfter, 
                                                  Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);

}