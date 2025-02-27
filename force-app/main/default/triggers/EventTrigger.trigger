trigger EventTrigger on Event__c (before insert, before update, before delete) {

    if (Trigger.new != null && !Trigger.isDelete) {
        processUpdateObjectFields(Trigger.new);         
    }
    if (Trigger.old != null && Trigger.isDelete) {
        processObjectDeletion(Trigger.old);     
    }
 
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    private static void processUpdateObjectFields(List<Event__c> eventList) {
        Set<Id> eventsIdList =  new Set<Id>();
        for (Event__c eventRec : eventList) {
            if (eventRec.Id != null) {
                eventsIdList.add(eventRec.Id);
            }            
        }  
        Map<Id, Integer> numberOfEventsRegRecords = getNumberOfEventsRegRecordsForEvents(eventsIdList);
        
        for (Event__c eventRec : eventList) {            
            // Put MaxAttendees and AvailableSeats
            if (!CommonUtils.isFieldFilled(eventRec.MaxAttendees__c)) {
                Integer defaultMaxAttendees = 100; 
                Object maxAttendees = CommonUtils.getCustomMetadataFieldValue('Event_Setting__mdt','Default','Max_available_seats__c');
                eventRec.MaxAttendees__c = (maxAttendees != null) ? Integer.valueOf(maxAttendees) : defaultMaxAttendees;                
            }
            Integer numberOfEventReg = (Integer) numberOfEventsRegRecords.get(eventRec.Id);
            eventRec.AvailableSeats__c = calculateAvailableSeats(Integer.valueOf(eventRec.MaxAttendees__c), numberOfEventReg);                
            // Control MaxAttendees and AvailableSeats
            if (eventRec.MaxAttendees__c <= 0) {
                eventRec.addError('Event error: MAX number of attendees cannot be negative');
            }else {
                if (CommonUtils.isFieldFilled(eventRec.MaxAttendees__c) && CommonUtils.isFieldFilled(eventRec.AvailableSeats__c)) {
                    if (eventRec.AvailableSeats__c < 0) {
                        eventRec.addError('Event error: Problem when calculating available seats. Available:'+eventRec.AvailableSeats__c);
                    }
                    if (eventRec.AvailableSeats__c > eventRec.MaxAttendees__c) {
                        eventRec.addError('Event error: Problem when calculating available seats. MAX:'+eventRec.MaxAttendees__c+', Available:'+eventRec.AvailableSeats__c);
                    }
                }
            }
        }        
    }

    private static void processObjectDeletion(List<Event__c> eventList) {
        Set<Id> eventsIdList =  new Set<Id>();
        for (Event__c eventRec : eventList) {
            eventsIdList.add(eventRec.Id);
        }
        List<Event_Registration__c> eventsRegIdList = [SELECT Id FROM Event_Registration__c WHERE Event__c IN :eventsIdList];
        try {
            Database.delete(eventsRegIdList);
        } catch (DmlException e) {
            System.debug('ERROR_Bug: ' + e.getMessage());
            throw new CommonUtils.CustomException('---Event error!!! ' + e.getMessage());
        }
    }

    private static Map<Id, Integer> getNumberOfEventsRegRecordsForEvents(Set<Id> idEvents) {
        Map<Id, Integer> countRegMap = new Map<Id, Integer>();
        if (idEvents !=null && !idEvents.isEmpty()) {
            List<AggregateResult> results = [SELECT COUNT(Id), Event__c FROM Event_Registration__c WHERE Event__c IN :idEvents GROUP BY Event__c];
            for (AggregateResult ar : results) {
                Integer count = (Integer) ar.get('expr0');
                Id eventId = (Id) ar.get('Event__c');
                countRegMap.put(eventId,count);
            }
        }
        return countRegMap;
    }

    private static Integer calculateAvailableSeats(Integer maxAttendees, Integer numberOfEventReg) {
        return maxAttendees - (numberOfEventReg == null ? 0 : numberOfEventReg);
    }

}