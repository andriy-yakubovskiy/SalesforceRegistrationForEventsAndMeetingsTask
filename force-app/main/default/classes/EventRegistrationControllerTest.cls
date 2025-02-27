@isTest
public class EventRegistrationControllerTest {

    @testSetup
    static void setupTestData() {
        Event__c testEvent = new Event__c(
            Name = 'Event for users',
            AvailableSeats__c = 80,
            MaxAttendees__c = 100,
            Date__c = Date.today(),
            Location__c = 'London'
        );
        insert testEvent;
        
        Contact existingContact = new Contact(
            LastName = 'Mik',
            FirstName = 'Miks',
            Email = 'example@gmail.com',
            Phone = '+1-123-65-98-6547',
            LeadSource = 'Web'
        );
        insert existingContact;
        
        Event_Registration__c regEvent = new Event_Registration__c(
            Event__c = testEvent.Id,
            Attendee__c = existingContact.Id
        );
        insert regEvent;
    }
    
    @isTest
    private static void testRegisterContactForEvent_NewContact() {     
        String newEmail = 'newuser2000@gmail.com';

        Event__c testEvent = [SELECT Id FROM Event__c LIMIT 1];
        
        Test.startTest();
        EventRegistrationController.registerContactForEvent(
            testEvent.Id,
            'User',
            'Testik',
            '+1-321-21-00-0001',
            newEmail
        );
        Test.stopTest();
        
        List<Contact> newContacts = [SELECT Id, Email, FirstName, LastName, Phone FROM Contact WHERE Email = :newEmail];
        System.assertEquals(1, newContacts.size(), 'New contact not created.');
        
        Id idContact = newContacts[0].Id;
        List<Event_Registration__c> regs = [SELECT Id, Event__c, Attendee__c FROM Event_Registration__c WHERE Event__c = :testEvent.Id AND Attendee__c = :idContact];
        System.assertEquals(1, regs.size(), 'Error: A registration for a new contact must be created.');
    }
    
    @isTest
    private static void testRegisterContactForEvent_ExistingContact() { 
        
        Event__c newTestEvent = new Event__c(
            Name = 'New TestEvent',
            AvailableSeats__c = 100,
            MaxAttendees__c = 100,
            Date__c = Date.today(),
            Location__c = 'New Location'
        );
        insert newTestEvent;
        
        String oldEmail = 'example@gmail.com';
        Contact existingContact = [SELECT Id, Email, FirstName, LastName FROM Contact WHERE Email = :oldEmail LIMIT 1];
        
        Test.startTest();
        EventRegistrationController.registerContactForEvent(
            newTestEvent.Id,
            existingContact.LastName,
            existingContact.FirstName,
            '+1-321-21-00-0002',
            existingContact.Email
        );
        Test.stopTest();
        
        List<Event_Registration__c> regs = [SELECT Id, Event__c, Attendee__c FROM Event_Registration__c 
                                                                                    WHERE Event__c = :newTestEvent.Id AND Attendee__c = :existingContact.Id];
        System.assertEquals(1, regs.size(), 'Registration error.');
    }
    
    static testMethod void testRegisterContactForEvent_ErrorContact() {  
        Event__c testEvent = [SELECT Id FROM Event__c LIMIT 1];
        
        try {
            Test.startTest();
            EventRegistrationController.registerContactForEvent(
                testEvent.Id,
                null, // LastName - specially empty
                'Error',
                '+1-321-21-00-0003',
                'error@gmail.com'
            );
            Test.stopTest();
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            System.assert(true, e.getMessage());
        }
    }
    
    static testMethod void testRegisterContactForEvent_ErrorEvent() { 
        String oldEmail = 'example@gmail.com';
        Contact existingContact = [SELECT Id, Email, FirstName, LastName FROM Contact WHERE Email = :oldEmail LIMIT 1];

        try {
            Test.startTest();
            EventRegistrationController.registerContactForEvent(
                null, // ID - specially empty
                existingContact.LastName,
                existingContact.FirstName,
            '   +1-321-21-00-0004',
                existingContact.Email
            );
            Test.stopTest();
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            System.assert(true, e.getMessage());
        }
    }

}