public class StaleJobAppScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        // Enqueue the job to close stale job applications
        System.enqueueJob(new CloseStaleJobApplicationsQueueable());
    }
}

