public class InvoiceEmailService implements Queueable, Database.AllowsCallouts {
    private List<Id> registrationIds;
    
    public InvoiceEmailService(List<Id> registrationIds) {
        this.registrationIds = registrationIds;
    }
    
    public void execute(QueueableContext context) {
        if (!CommonUtils.isFieldFilled(registrationIds)) {
            CommonUtils.logError('Registration Id is empty!', 'InvoiceEmailService.execute');
            System.debug('Registration Id is empty. Ids = ' + registrationIds);
            return;
        }
        List<Event_Registration__c> regs = [SELECT Id, Event__r.Name, Attendee__r.Name, Attendee__r.Email FROM Event_Registration__c WHERE Id IN :registrationIds];

        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        
        for (Event_Registration__c reg : regs) {
            Id regId = reg.Id;
            if (reg.Attendee__r != null && reg.Attendee__r.Email != null && CommonUtils.isFieldFilled(reg.Attendee__r.Email)) {
                try {
                    // Visualforce Pages in BinaryFormat(Blob)
                    PageReference pdfPage = Page.InvoicePDF;
                    pdfPage.getParameters().put('registrationId', regId);
                    Blob pdfBlob = pdfPage.getContentAsPDF();

                    // Attachment files
                    Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
                    fileAttachment.fileName = 'Invoice_' + regId + '.pdf';
                    fileAttachment.body = pdfBlob;
                    
                    // Email message 
                    Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();
                    emailMsg.setToAddresses(new List<String>{ reg.Attendee__r.Email });
                    emailMsg.setSubject('Your Invoice for Registration ' + regId);
                    emailMsg.setPlainTextBody(
                        'Dear ' + reg.Attendee__r.Name + ',\n\n' +
                        'Please find attached your invoice for your registration.\n\n' +
                        'Best regards,\nYour Company'
                    );
                    emailMsg.setFileAttachments(new List<Messaging.EmailFileAttachment>{ fileAttachment });
                    
                    emailMessages.add(emailMsg);

                } catch (Exception e) {
                    CommonUtils.logError(e.getMessage(), 'InvoiceEmailService.execute');
                    System.debug('Error generating PDF for registration ' + regId + ': ' + e.getMessage());
                }
            }   
        }
        
        if (!emailMessages.isEmpty()) {
            Messaging.sendEmail(emailMessages);
        }
    }
}