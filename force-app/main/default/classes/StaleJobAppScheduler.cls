public class StaleJobAppScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        System.enqueueJob(new CloseStaleJobApplicationsQueueable());
    }
}