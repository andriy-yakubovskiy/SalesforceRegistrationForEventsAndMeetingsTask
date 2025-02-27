import { LightningElement, api, track} from 'lwc';
import USER_ID from '@salesforce/user/Id';
import localUtils from 'c/utilitiesModule';
import getCurrentUser from '@salesforce/apex/CommonUtils.getCurrentUser';
import registerContactForEvent from '@salesforce/apex/EventRegistrationController.registerContactForEvent';
import doesRecordExist from '@salesforce/apex/CommonUtils.doesRecordExist';

export default class EventRegistration extends LightningElement {
    @api eventId;
    @api eventName;
    @api eventDate;
    @track contactFields = {
            lastName: null,
            firstName: null,
            phone: null,
            email: null
        };
    isUserLoggedIn = false;
    isLoading = false;
    textSuccess = '';

    connectedCallback() {
        this.isUserLoggedIn = (USER_ID !== undefined);
    }

    handleLoadUserData() {
        getCurrentUser({userId: USER_ID})
            .then(data => {
                this.contactFields.lastName     = data.LastName;
                this.contactFields.firstName    = data.FirstName;
                this.contactFields.phone        = data.Phone;
                this.contactFields.email        = data.Email;                
            })
            .catch(error => {
                console.error(error);
                let errorMessage = localUtils.parseErrorMessage(error);
                localUtils.showToast(this,'Warning!!!', 'Error loading user data:' + errorMessage, 'error');
            });
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleContactLastNameChange(event) {
        this.contactFields.lastName     = event.target.value;
    }
    handleContactFirstNameChange(event) {
        this.contactFields.firstName    = event.target.value;
    }
    handleContactPhoneChange(event) {
        this.contactFields.phone        = event.target.value;
    }
    handleContactEmailChange(event) {
        this.contactFields.email        = event.target.value;
    }

    handleSubmit() {
        let errControl = false;
        if (!this.contactFields.lastName) {
            errControl = true;
            localUtils.showToast(this,'Warning!!!', 'Last name is required!', 'error')            
        }
        if (!this.contactFields.email) {
            errControl = true;
            localUtils.showToast(this,'Warning!!!', 'E-mail is required!', 'error');
        } else if (!localUtils.isValidEmail(this.contactFields.email)) {
            errControl = true;
            localUtils.showToast(this,'Warning!!!', 'Please, enter a correct email address!', 'error');
        }
        if (errControl) {
            return;
        }
        this.isLoading = true;
        doesRecordExist({recordId: this.eventId})
            .then(result => {
                if (result) { 
                    registerContactForEvent({ eventId: this.eventId, 
                                            lastName: this.contactFields.lastName, 
                                            firstName: this.contactFields.firstName, 
                                            phone: this.contactFields.phone, 
                                            email: this.contactFields.email })
                    .then(() => {
                        this.isLoading = false;
                        this.textSuccess = 'Registration information sent to email \''+this.contactFields.email+'\'';
                        localUtils.showToast(this,'Success', 'You have successfully registered!', 'success', 'pester');
                        setTimeout(() => {
                            window.location.reload();
                        }, 5000);
                    })
                    .catch(error => {
                        this.isLoading = false;
                        this.textSuccess = '';
                        console.error(error);
                        let errorMessage = localUtils.parseErrorMessage(error);
                        localUtils.showToast(this,'Registration error', errorMessage, 'error');                
                    });
                } else {
                    this.isLoading = false;
                    this.textSuccess = '';
                    let errorMessage = 'Error accessing event!';
                    localUtils.showToast(this,'Registration error', errorMessage, 'error');
                    setTimeout(() => {
                        window.location.reload();
                    }, 1000);
                }                               
            })
            .catch(error => {
                this.isLoading = false;
                this.textSuccess = '';
                setTimeout(() => {
                    window.location.reload();
                }, 1000);
                console.error(error);                    
            });   
    }
    
}