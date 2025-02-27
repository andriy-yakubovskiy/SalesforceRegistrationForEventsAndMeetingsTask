import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export function formatTime(milliseconds) {
    let formattedTime;
    if (!milliseconds && milliseconds !== 0)  
        formattedTime = '-';
    else {
        const hours = Math.floor(milliseconds / (1000 * 60 * 60));
        const minutes = Math.floor((milliseconds % (1000 * 60 * 60)) / (1000 * 60));
        formattedTime = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
    }
    return formattedTime;
}

export function isValidEmail(email) {
    const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailPattern.test(email);
}

export function showToast(component, title, message, variant, mode='sticky') {
    const toastEvent = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
            // "success"
            // "error"
            // "warning"
            // "info"
        mode: mode
            // 'sticky' close only manually
            // 'pester' close after 3 sec
            // 'dismissable' for automatic
    });
    component.dispatchEvent(toastEvent);
}

export function parseErrorMessage(error) {
    let textMessage = 'Unknown error. Please try again later.';
    if (error && error.body && error.body.message) {
        let errorMessage = error.body.message;
        errorMessage = errorMessage.replace(': []', '').trim();
        //-Event registration error
        //--There are no available seats for related event
        if (errorMessage.includes('Event registration error:') && errorMessage.includes('There are no available seats for related event')) {
            const index = errorMessage.indexOf('There are no available seats for related event');
            textMessage = errorMessage.slice(index).trim();
        }
        //--Problem when calculating available seats
        else if (errorMessage.includes('Event registration error:') && errorMessage.includes('Problem when calculating available seats')) {
            const index = errorMessage.indexOf('Problem when calculating available seats');
            textMessage = errorMessage.slice(index).trim();
        }
        //--"Event" not found, for event registration
        else if (errorMessage.includes('Event registration error:') && errorMessage.includes('"Event" not found, for event registration')) {
            const index = errorMessage.indexOf('"Event" not found, for event registration');
            textMessage = errorMessage.slice(index).trim();
        }
        else {
            textMessage = errorMessage;
        }
    }
    return textMessage;
}