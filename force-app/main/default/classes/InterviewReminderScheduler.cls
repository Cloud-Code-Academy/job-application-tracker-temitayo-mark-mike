public with sharing class InterviewReminderScheduler implements Schedulable {
    public void execute(SchedulableContext context) {
        // Calculate start and end of tomorrow using Date class
        Date tomorrow = System.today().addDays(1);
        DateTime startTime = DateTime.newInstance(tomorrow.year(), tomorrow.month(), tomorrow.day());
        DateTime endTime = startTime.addDays(1);

        List<Event> upcoming = [
            SELECT Id FROM Event
            WHERE StartDateTime >= :startTime AND StartDateTime < :endTime
        ];

        if (!upcoming.isEmpty()) {
            List<Id> interviewIds = new List<Id>();
            for (Event e : upcoming) {
                interviewIds.add(e.Id);
            }

            System.enqueueJob(new EmailNotificationQueueable(
                interviewIds,
                EmailNotificationQueueable.EmailType.INTERVIEW_REMINDER
            ));
        }
    }
}