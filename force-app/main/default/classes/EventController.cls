public with sharing class EventController {
    
    //@AuraEnabled(cacheable=true)
    @AuraEnabled
    public static List<Event__c> getAvailableEvents() {
        return [SELECT Id, Name, Type_of_event__c, Date__c, DateTime__c, Location__c, AvailableSeats__c, MaxAttendees__c 
                FROM Event__c 
                WHERE Actual__c = true AND AvailableSeats__c > 0 
                ORDER BY Date__c ASC];
    }
    
}