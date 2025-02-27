import { LightningElement, track} from 'lwc';
import localUtils from 'c/utilitiesModule';
import getEvents from '@salesforce/apex/EventController.getAvailableEvents';
import getCustomMetadataFieldValue from '@salesforce/apex/CommonUtils.getCustomMetadataFieldValue';
import doesRecordExist from '@salesforce/apex/CommonUtils.doesRecordExist';

export default class EventList extends LightningElement {
    @track eventsCatalog = [];
    isLoading = true;
    reportId;
    get isEventsCatalog() {
        return this.eventsCatalog && this.eventsCatalog.length > 0;
    }

    // //Variant_1 - Necessarily use '@AuraEnabled(cacheable=true)' for getAvailableEvents
    // @wire(getEvents)
    // obtainingEvents({ error, data }) {
    //     this.isLoading = false;
    //     if (data) {
    //         this.eventsCatalog = data.map(event => ({
    //             ...event,
    //             formatDateTime: event.DateTime__c ? localUtils.formatTime(event.DateTime__c) : '-'
    //         }));
    //     } else if (error) {
    //         console.error(error);
    //     }
    // }
    //Variant_2    
    getEventsCatalog(){   
        getEvents()
            .then(result => {
                this.isLoading = false;
                this.eventsCatalog = result.map(event => ({
                    ...event,
                    formatDateTime: event.DateTime__c ? localUtils.formatTime(event.DateTime__c) : '-'
                }));                                
            })
            .catch(error => {
                console.error(error);
                this.isLoading = false;
                this.eventsCatalog = [];
                let errorMessage = localUtils.parseErrorMessage(error);
                localUtils.showToast(this,'Error getting Events!', errorMessage, 'error');                
            })
    }

    connectedCallback() {
       this.handleRefreshData();
    }

    handleRefreshData(){
        this.getEventsCatalog();
    }
    
    handleRegister(event) {
        const eventId = event.target.dataset.id;
        const eventName = event.target.dataset.name;
        const eventDate = event.target.dataset.date;
        doesRecordExist({recordId: eventId})
            .then(result => {
                if (result) {
                    const registerEvent = new CustomEvent('registernewevent', {
                        detail : { eventId, eventName, eventDate}
                    });
                    this.dispatchEvent(registerEvent);
                } else {
                    this.handleRefreshData();
                }                               
            })
            .catch(error => {
                console.error(error);
                this.handleRefreshData();
            });         
    }

    handleOpenReportEvents() {
        getCustomMetadataFieldValue({metadataObjectName: 'Event_Setting__mdt', developerName: 'Default', fieldName: 'Report_ID__c'})
            .then(result => {
                this.reportId = result;            
                if (this.reportId) {
                    const url = `${window.location.origin}/lightning/r/Report/${this.reportId}/view`;
                    window.location.href = url;   
                } else {
                    localUtils.showToast(this,'Attention!!!', 'Report ID is not specified in the settings!', 'error');
                }                
            })
            .catch(error => {
                this.reportId = '';
                console.error(error);
                let errorMessage = localUtils.parseErrorMessage(error);
                localUtils.showToast(this,'Error fetching custom metadata value (reportId)!', errorMessage, 'error'); 
            });               
    }
    
}