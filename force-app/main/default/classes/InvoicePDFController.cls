public with sharing class InvoicePDFController {
    public class DataPDFController {
        public Date eventDate { get; set; }
        public String eventName { get; set; }
        public String attendeeName { get; set; }
        public Date regDate { get; set; }
        public String regId { get; set; }

        public DataPDFController() {
            eventDate    = null;
            eventName    = '';
            attendeeName = '';
            regDate      = null;
            regId        = '';   
        }
    }
    public DataPDFController data { get; set; }
    
    public InvoicePDFController() {        
        this.data = new DataPDFController();        

        String regId = ApexPages.currentPage().getParameters().get('registrationId');        
        if (regId != null) {
            Event_Registration__c registration = [SELECT Id, RegistrationDate__c, Event__r.Name, Event__r.Date__c, Attendee__r.Name, Attendee__r.Email FROM Event_Registration__c WHERE Id = :regId LIMIT 1];
            if (registration != null) {
                data.regDate = registration.RegistrationDate__c; 
                data.regId = String.valueOf(registration.Id); 
                if (registration.Event__r != null) {
                    data.eventDate = registration.Event__r.Date__c;
                    data.eventName = registration.Event__r.Name; 
                    data.attendeeName = registration.Attendee__r.Name; 
                }               
            }            
        }
    }

}