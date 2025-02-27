import { LightningElement, track } from 'lwc';

export default class EventPage extends LightningElement {
    @track selectedEvent = {
        id: null,
        name: null,
        date: null
    };
    get isEventSelected() {
        return (this.selectedEvent !== null && this.selectedEvent.id !== null);
    }

    handleClose() {
        this.selectedEvent.id = null;
    }

    handleEventRegister(event) {
        this.selectedEvent.id = event.detail.eventId;
        this.selectedEvent.name = event.detail.eventName;
        this.selectedEvent.date = event.detail.eventDate;        
    }
}