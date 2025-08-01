public class CloseStaleJobApplicationsQueueable implements Queueable, Database.AllowsCallouts {

    // Execute method that will run when the job is processed
    public void execute(QueueableContext context) {
        // Calculate the date 30 days ago from today
        Date thirtyDaysAgo = Date.today().addDays(-30);

        // Query for job applications that are not closed or accepted and have a follow-up date more than 30 days ago
        List<Job_Application__c> staleApps = [
            SELECT Id, Status__c, Follow_up_Date__c, Notes__c
            FROM Job_Application__c
            WHERE Status__c != 'Closed'
              AND Status__c != 'Accepted'
              AND Follow_up_Date__c <= :thirtyDaysAgo
              LIMIT 200
        ];

        // Create a list to hold the applications that will be updated
        List<Job_Application__c> updates = new List<Job_Application__c>();

        // Loop through the stale applications
        for (Job_Application__c app : staleApps) {
            // Set the status to closed
            app.Status__c = 'Closed';
            // Append a note to the existing notes field, or create a new note if none exists
            String oldNote = app.Notes__c != null ? app.Notes__c + '\n' : '';
            app.Notes__c = oldNote + 'Closed automatically due to inactivity on ' + String.valueOf(Date.today()) + '.';
            // Add the updated application to the list of updates
            updates.add(app);
        }

        // If there are updates to be made, perform the update
        if (!updates.isEmpty()) {
            update updates;
        }
    }
}