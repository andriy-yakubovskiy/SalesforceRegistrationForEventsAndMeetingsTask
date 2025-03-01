# Registration for Events and Meetings App
The application provides the ability to register users for events and meetings within the Salesforce system..

## Technologies which are used in App
**Apex:** Backend development *(SOQL, DML, Triggers, Queueable, Apex-Tests)*.<br>
**JavaScript, HTML, CSS:** Frontend development *(Event Handling, Wire-Adapters and Apex-controller, SLDS)*.<br>
**Lightning Web Components (LWC) / Visualforce:** User interface *(UI)* in Salesforce.<br>
**Flow:** A tool for automating processes *(Flow Builder, Screen Flow, Record-Triggered Flow)*.<br>

## Business Process of App
**Selection of an event or meeting:<br>**
The user visits the main page of the application and look through list of upcoming events and meetings.
![image](https://github.com/user-attachments/assets/d63aada3-9d7c-4616-b0ea-42d7abd602e4)
<br>
<br>
<br>
**Filling out the registration form:<br>**
After selecting an event, the user navigates to the registration page and fills out a form with personal data (such as name, email, and contact phone) or uses the “Fill Current User Data” button.
![image](https://github.com/user-attachments/assets/4ed04216-204a-4f27-bcc1-a039a59402e1)
<br>
<br>
<br>
**Creating a record in Salesforce:<br>**
Upon successful registration, a new registration record is created, linking the user to the selected event or meeting.
![image](https://github.com/user-attachments/assets/7e58a2e5-e6fc-41f2-b0dc-295c85ad846d)
<br>
<br>
<br>
**Sending registration notifications:<br>**
After registration, the system sends the user a confirmation notification. Shortly afterward, an email with an attached Invoice file is also sent.
![image](https://github.com/user-attachments/assets/cda9f589-280e-47ec-bc52-c69cbc0f0387)
<br>
<br>
<br>
**Sending reminder notifications:<br>**
A few days before the event, the system uses Flow to send reminders to both registered users and the event organizer.
![image](https://github.com/user-attachments/assets/4d1afc7f-92ff-4c4b-a4e2-d2514e5e4283)
<br>
<br>
<br>
**Administrative management:<br>**
Organizers and administrators have access to the control panel for viewing, editing, and analyzing data, for example, through the “Registered users for the events” report.
![image](https://github.com/user-attachments/assets/64da8275-dfc8-43c1-ab09-5f304ac8e5d1)
<br>
<br>
<br>
**Additional features:<br>**
Added a "Bulk delete" button for selected records from the standard ListView.
![image](https://github.com/user-attachments/assets/d58e4da3-e8ac-45f4-95b6-de37c4bbfff2)
<br>
<br>
<br>

-------------
git clone https://github.com/andriy-yakubovskiy/SalesforceRegistrationForEventsAndMeetingsTask.git
