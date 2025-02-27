import { LightningElement, api} from 'lwc';
import getObjectApiName from '@salesforce/apex/CommonUtils.getObjectApiName';
import deleteRecords from '@salesforce/apex/CommonUtils.deleteSelectedRecords';

export default class DeleteRecordsButtonInListView extends LightningElement {
    @api recordIds; // Get selected records from ListView via other resource
    objectApiName;

    textMessenger = '';
    isWait = true;
    isEmptyList = true;

    initValue(){
        this.isWait = false;
        this.textMessenger = '';
        if (this.recordIds && this.recordIds.length !== 0) {            
            this.isEmptyList = false;
            if (this.recordIds.length === 1) {
                this.textMessenger = 'Confirm delete selected object.';
            } else {
                this.textMessenger = 'Confirm delete selected of '+this.recordIds.length+' objects.';
            }            
            // Get the Object by Id         
            getObjectApiName({ recordId: this.recordIds[0] })
                .then(result => {
                    this.objectApiName = result;
                })
                .catch(error => {
                    console.error('Error getting objectApiName: ', error);
                });                        
        } else {
            this.isEmptyList = true;
            this.textMessenger = 'The list of elements to delete is empty.';
        }
    }

    connectedCallback(){
        this.initValue(); 
    }

    handleClose(waitTime=1000){
		setTimeout(() => {
            window.history.back();
        }, waitTime);        
	}

    handleDelete() {        
        if (!this.recordIds || this.recordIds.length === 0) {
            alert('Please select at least one record!');
            return;
        }
        if (!this.objectApiName) {
            alert('Error deleting records via component button!');
            return;
        }
        this.isWait = true;
        deleteRecords({ objectName: this.objectApiName, recordIds: this.recordIds })
            .then(() => {
                this.isWait = false;
                this.isEmptyList = true;        
                this.textMessenger = 'Success!';
                this.handleClose(3000);
            })
            .catch(error => {
                this.isWait = false;
                this.initValue();
                this.textMessenger = 'Try again! Error: '+error.body.message;
                alert(error.body.message);                
            });
    }
}