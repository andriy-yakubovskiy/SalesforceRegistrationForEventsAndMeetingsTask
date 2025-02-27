public with sharing class EventRegistrationTriggerHandler {
    
    public static void handleTrigger(Boolean isInsert, Boolean isUpdate, Boolean isDelete,
                                    Boolean triggerisBefore, Boolean triggerisAfter,
                                    List<Event_Registration__c> triggerListNew, List<Event_Registration__c> triggerListOld,
                                    Map<Id, Event_Registration__c> triggerMapNew, Map<Id, Event_Registration__c> triggerMapOld) {
        EventAttendeeList eventsAndAttendees = getEventsAndAttendees(triggerListNew, triggerListOld);
        Set<Id> newEventsIds = eventsAndAttendees.newEventsIds;
        Set<Id> oldEventsIds = eventsAndAttendees.oldEventsIds;
        Set<Id> allEventsIds = eventsAndAttendees.allEventsIds;
        Map<Id, Event__c> allEventsMap = eventsAndAttendees.allEventsMap;
        Set<Id> newAttendeesIds = eventsAndAttendees.newAttendeesIds;        
        Map<Id, Contact> newAttendeesMap = eventsAndAttendees.newAttendeesMap;

        if (!allEventsMap.isEmpty()) {
            if (triggerisBefore) {
                handleBeforeTrigger(triggerListNew, allEventsMap, newAttendeesMap);
            } else if (triggerisAfter) {
                handleAfterTrigger(isInsert, triggerListNew, allEventsMap, newAttendeesMap);               
            }
        }
    }
    
    private static void handleBeforeTrigger(List<Event_Registration__c> triggerListNew,
                                            Map<Id, Event__c> eventsMap,
                                            Map<Id, Contact> attendeesMap) {
        // Generate Name for RegEvent
        if (triggerListNew != null) {            
            for (Event_Registration__c regEvent : triggerListNew) {
                Event__c objEvent;
                Contact objContact;
                if (regEvent.Event__c != null && eventsMap.containsKey(regEvent.Event__c)) {
                    objEvent = eventsMap.get(regEvent.Event__c);                    
                }
                if (regEvent.Attendee__c != null && attendeesMap.containsKey(regEvent.Attendee__c)) {
                    objContact = attendeesMap.get(regEvent.Attendee__c);                    
                }
                regEvent.Name = generateRegEventName(objEvent, objContact);
            }
        }
    }
    
    private static void handleAfterTrigger(Boolean isInsert,
                                           List<Event_Registration__c> triggerListNew,
                                           Map<Id, Event__c> allEventsMap,
                                           Map<Id, Contact> newAttendeesMap) {
        // Update related Event
        performUpdateObjectEvents(allEventsMap, triggerListNew);
        
        // Send Email to Attendee
        if (isInsert){
            sendRegistrationEmails(triggerListNew, newAttendeesMap, allEventsMap);
            sendInvoiceEmails(triggerListNew);
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    public class EventAttendeeList {
        public Set<Id> newEventsIds { get; set; }
        public Set<Id> oldEventsIds { get; set; }
        public Set<Id> allEventsIds { get; set; }
        public Map<Id, Event__c> allEventsMap { get; set; }
        public Set<Id> newAttendeesIds { get; set; }
        public Map<Id, Contact> newAttendeesMap { get; set; }
        
        
        public EventAttendeeList() {
            newEventsIds    = new Set<Id>();
            oldEventsIds    = new Set<Id>();
            allEventsIds    = new Set<Id>();
            allEventsMap    = new Map<Id, Event__c>();
            newAttendeesIds = new Set<Id>();
            newAttendeesMap = new Map<Id, Contact>();
            
        }
    }

    private static EventAttendeeList getEventsAndAttendees(List<Event_Registration__c> triggerListNew, List<Event_Registration__c> triggerListOld) {
        EventAttendeeList eventsAttendees = new EventAttendeeList();
        
        if (triggerListNew != null) {
            for (Event_Registration__c regEvent : triggerListNew) {
                if (regEvent.Event__c != null) {
                    eventsAttendees.newEventsIds.add(regEvent.Event__c);
                }
                if (regEvent.Attendee__c != null) {
                    eventsAttendees.newAttendeesIds.add(regEvent.Attendee__c);
                }
            }
        }
        if (triggerListOld != null) {
            for (Event_Registration__c oldRegEvent : triggerListOld) {
                if (oldRegEvent.Event__c != null) {
                    eventsAttendees.oldEventsIds.add(oldRegEvent.Event__c);
                }
            }
        }
        eventsAttendees.allEventsIds.addAll(eventsAttendees.newEventsIds);
        eventsAttendees.allEventsIds.addAll(eventsAttendees.oldEventsIds);

        if (!eventsAttendees.allEventsIds.isEmpty()) {
            eventsAttendees.allEventsMap = getEventsMap(eventsAttendees.allEventsIds);
        }
        if (!eventsAttendees.newAttendeesIds.isEmpty()) {
            eventsAttendees.newAttendeesMap = getAttendeesMap(eventsAttendees.newAttendeesIds);
        }

        return eventsAttendees;
    }
    
    private static Map<Id, Event__c> getEventsMap(Set<Id> Ids) {
        Map<Id, Event__c> eventsMap = new Map<Id, Event__c>();
        if (Ids !=null && !Ids.isEmpty()) {
            List<Event__c> eventsList = [SELECT Id, Name, Date__c, Location__c, AvailableSeats__c, MaxAttendees__c FROM Event__c WHERE Id IN :Ids];
            eventsMap = new Map<Id, Event__c>(eventsList);
        }
        return eventsMap;
    }
    
    private static Map<Id, Contact> getAttendeesMap(Set<Id> Ids) {
        Map<Id, Contact> attendeesMap = new Map<Id, Contact>();
        if (Ids !=null && !Ids.isEmpty()) {
            List<Contact> attendeesList = [SELECT Id, Name, Email FROM Contact WHERE Id IN :Ids];
            attendeesMap = new Map<Id, Contact>(attendeesList);
        }
        return attendeesMap;
    }
    
    private static String generateRegEventName(Event__c objEvent, Contact objContact) {
        String regEventName = (objEvent !=null && objEvent.Name != null) ? objEvent.Name : 'Unnamed Event';
        String contactName = (objContact !=null && objContact.Name != null) ? objContact.Name : 'Unnamed Contact';
        regEventName += ' (' + contactName + ')';        
        return regEventName;
    }
    
    private static void performUpdateObjectEvents(Map<Id,Event__c> eventsMap, List<Event_Registration__c> triggerListNew) {
        Set<Event__c> eventsToUpdate = new Set<Event__c>(eventsMap.values());
        if (!eventsToUpdate.isEmpty()) {
            try {
                List<Event__c> eventsList = new List<Event__c>(eventsToUpdate);
                update eventsList;
            } catch (DmlException e) {
                System.debug('ERROR_Bug: ' + e.getMessage());
                //Collect IDs of failed and error message to related object Event_Registration
                if (triggerListNew != null) {
                    Set<Id> failedEventIds = new Set<Id>();
                    for (Integer i = 0; i < e.getNumDml(); i++) {
                        if (e.getDmlId(i) != null) {
                            failedEventIds.add(e.getDmlId(i));
                        }
                    }
                    for (Event_Registration__c regEvent : triggerListNew) {
                        if (failedEventIds.contains(regEvent.Event__c)) {
                            regEvent.addError('Event registration error: Problem when calculating available seats. ' + e.getMessage());
                        }
                    }
                } else {
                    throw new CommonUtils.CustomException('---Event registration error!!! ' + e.getMessage());
                }
            }
        }
    }

    private static void sendRegistrationEmails(List<Event_Registration__c> newRegistrations, Map<Id, Contact> newAttendeesMap, Map<Id, Event__c> allEventsMap) {
        if (newRegistrations == null || newRegistrations.isEmpty()) {
            return;
        }
        
         // Generating text and sending email to Attendees
         String subjectTemplate = 'Confirmation of registration for the event: {0}';
         String bodyTemplate = 'Hello {0},\n\n' +
                       'You are registered for the event: "{1}"\n' +
                       'Date: {2}\n' +
                       'Location: {3}\n\n' +
                       'We are waiting for you!';
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Event_Registration__c reg : newRegistrations) {
            if ((reg.Attendee__c != null && newAttendeesMap.containsKey(reg.Attendee__c)) && (reg.Event__c != null && allEventsMap.containsKey(reg.Event__c))) {
                Contact attendeeRec = newAttendeesMap.get(reg.Attendee__c); 
                if (attendeeRec != null && CommonUtils.isFieldFilled(attendeeRec.Email)) {
                    Event__c eventRec = allEventsMap.get(reg.Event__c);
                    
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    List<String> setToList = new List<String>{attendeeRec.Email};
                    email.setToAddresses(setToList);
                    String subject = String.format(subjectTemplate, new List<Object>{eventRec.Name});
                    email.setSubject(subject);                    
                    String body = String.format(bodyTemplate, new List<Object>{attendeeRec.Name, eventRec.Name, eventRec.Date__c, eventRec.Location__c});
                    email.setPlainTextBody(body);
                    
                    emails.add(email);
                }
            }
        }

        // Send Email to Attendee
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    private static void sendInvoiceEmails(List<Event_Registration__c> newRegistrations) {
        if (newRegistrations == null || newRegistrations.isEmpty()) {
            return;
        }

        Set<Id> regIds = new Set<Id>();
        for (Event_Registration__c reg : newRegistrations) {
            regIds.add(reg.Id);
        }

        if (!regIds.isEmpty()) {
            System.enqueueJob(new InvoiceEmailService(new List<Id>(regIds)));
        }
    }
    
}