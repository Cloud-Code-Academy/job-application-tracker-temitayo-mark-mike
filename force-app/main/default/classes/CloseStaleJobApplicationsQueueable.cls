public class CloseStaleJobApplicationsQueueable implements Queueable, Database.AllowsCallouts {

    public void execute(QueueableContext context) {
        Date thirtyDaysAgo = Date.today().addDays(-30);

        List<Job_Application__c> staleApps = [
            SELECT Id, Status__c, Follow_up_Date__c, Notes__c
            FROM Job_Application__c
            WHERE Status__c != 'Closed'
              AND Status__c != 'Accepted'
              AND Follow_up_Date__c <= :thirtyDaysAgo
              LIMIT 200
        ];

        List<Job_Application__c> updates = new List<Job_Application__c>();

        for (Job_Application__c app : staleApps) {
            app.Status__c = 'Closed';
            String oldNote = app.Notes__c != null ? app.Notes__c + '\n' : '';
            app.Notes__c = oldNote + 'Closed automatically due to inactivity on ' + String.valueOf(Date.today()) + '.';
            updates.add(app);
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }
}