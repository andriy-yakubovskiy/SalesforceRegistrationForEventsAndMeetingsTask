@isTest
public class EventRegistrationTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        Event__c testEvent = new Event__c(
            Name = 'Event for Users',
            MaxAttendees__c = 100,
            AvailableSeats__c = 50,
            Date__c = Date.newInstance(2024, 1, 1),
            Location__c = 'Kyiv'
        );
        insert testEvent;
        
        Contact testContact = new Contact(
            LastName = 'User Name',
            FirstName = 'Test Name',
            Email = 'testuser@gmail.com'
        );
        insert testContact;
        
        Event_Registration__c reg = new Event_Registration__c(
            Event__c = testEvent.Id,
            Attendee__c = testContact.Id
        );
        insert reg;
    }
    
    static testMethod void testHandleTrigger_Before() {
        Event_Registration__c reg = [SELECT Id, Event__c, Attendee__c, Name FROM Event_Registration__c LIMIT 1];
        
        List<Event_Registration__c> triggerListNew = new List<Event_Registration__c>{ reg };
        List<Event_Registration__c> triggerListOld = new List<Event_Registration__c>();
        Map<Id, Event_Registration__c> triggerMapNew = new Map<Id, Event_Registration__c>{ reg.Id => reg };
        Map<Id, Event_Registration__c> triggerMapOld = new Map<Id, Event_Registration__c>();
        
        Test.startTest();
        EventRegistrationTriggerHandler.handleTrigger(
            false, // isInsert
            false, // isUpdate
            false, // isDelete
            true,  // triggerisBefore
            false, // triggerisAfter
            triggerListNew,
            triggerListOld,
            triggerMapNew,
            triggerMapOld
        );
        Test.stopTest();
        
        reg = [SELECT Name FROM Event_Registration__c WHERE Id = :reg.Id];
        String supposedName = 'Event for Users (Test Name User Name)';
        System.assertEquals(supposedName, reg.Name, 'Registration name should be generated correctly in before context.');
    }
    
    @isTest
    private static void testHandleTrigger_After() {        
        Event__c testEvent = [SELECT Id, Name, Date__c, Location__c FROM Event__c LIMIT 1];
        Contact testContact = [SELECT Id, Name, Email FROM Contact LIMIT 1];
        Event_Registration__c newReg = new Event_Registration__c(
            Event__c = testEvent.Id,
            Attendee__c = testContact.Id
        );
        insert newReg;
        
        List<Event_Registration__c> triggerListNew = new List<Event_Registration__c>{ newReg };
        List<Event_Registration__c> triggerListOld = new List<Event_Registration__c>{ newReg };
        Map<Id, Event_Registration__c> triggerMapNew = new Map<Id, Event_Registration__c>{ newReg.Id => newReg };
        Map<Id, Event_Registration__c> triggerMapOld = new Map<Id, Event_Registration__c>{ newReg.Id => newReg };
        
        Test.startTest();
        EventRegistrationTriggerHandler.handleTrigger(
            true,  // isInsert
            false, // isUpdate
            false, // isDelete
            false, // triggerisBefore
            true,  // triggerisAfter
            triggerListNew,
            triggerListOld,
            triggerMapNew,
            triggerMapOld
        );
        Test.stopTest();
        
        // check email sending limits
        Integer emailInvocations = Limits.getEmailInvocations();
        System.debug('emailInvocations: ' + emailInvocations);
        System.assert(emailInvocations > 0, 'At least one email should be sent in after trigger context.');
    }
}