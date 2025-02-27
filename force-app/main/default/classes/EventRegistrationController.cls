public with sharing class EventRegistrationController {
    
    @AuraEnabled
    public static void registerContactForEvent(Id eventId, String lastName, String firstName, String phone, String email) {        
        
        Contact attendee = getAttendeeContact(lastName, firstName, phone, email);
        if (attendee != null && attendee.Id != null) {
            registerEventForAttendee(eventId, attendee.Id);
        } else {
            throw new AuraHandledException('Attendee registration error!!!');
        }
    }

    private static Contact getAttendeeContact(String lastName, String firstName, String phone, String email) {
        if (!CommonUtils.isFieldFilled(email)) {
            return null;
        }
        // Search Attendee/Сontact by e-mail
        ////List<Contact> resultsQuery = [SELECT Id FROM Contact WHERE Email = :email AND LeadSource = 'Web' LIMIT 1];
        String objectFields = 'Id';
        String objectName = 'Contact';
        Map<String, Object> objectfilter = new Map<String, Object>{
            'Email' => email
        };
        if (CommonUtils.checkPicklistValueAvailable(objectName, 'LeadSource', 'Web')) {
            objectfilter.put('LeadSource', 'Web');
        }
        String objectOtherQuery = 'LIMIT 1'; 
        List<Contact> resultsQuery = CommonUtils.executeDynamicQuerySOQL(objectName, objectFields, objectfilter, objectOtherQuery);
        
        // Create Attendee/Сontact
        ////-Variant_1
        // Map<String, Object> contactFields = new Map<String, Object>{
        //     'Email' => email,
        //     'FirstName' => firstName,
        //     'LastName' => lastName,
        //     'Phone' => phone,
        //     'LeadSource' => 'Web'
        // };
        // Contact objAttendee = new Contact();
        // for (String fieldName : contactFields.keySet()) {
        //     objAttendee.put(fieldName, contactFields.get(fieldName));
        // }
        //-Variant_2
        Contact objAttendee = new Contact(
            Email = email,
            FirstName = firstName,
            LastName = lastName,
            Phone = phone,
            LeadSource = 'Web'
            );
        
        // New or Update Attendee/Сontact
        if (!resultsQuery.isEmpty()) {
            objAttendee.Id = resultsQuery[0].Id;
        }
        try {
            //Database.upsert(objAttendee, false);
            upsert objAttendee;
        } catch (DmlException e) {
            throw new AuraHandledException('Event registration error: ' + e.getMessage());
        }
        
        return objAttendee;
    }

    private static void registerEventForAttendee(Id eventId, Id attendeeId) {    
        //New registration Сontact for Event, through object Event_Registration
        if (attendeeId != null) {
            try {
                Event_Registration__c registration = new Event_Registration__c(
                    Event__c = eventId,
                    Attendee__c = attendeeId,
                    Status__c = 'Registered',
                    RegistrationDate__c = System.today());
                insert registration;
            } catch (DmlException e) {
                System.debug('ERROR_Bug: ' + e.getMessage());
                throw new AuraHandledException(e.getMessage());
            }
        } else {
            throw new AuraHandledException('Error registering Attendee for Event!!!');
        }      
    }
    
}