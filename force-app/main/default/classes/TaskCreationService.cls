/**
 * @description Service class for creating tasks based on Job Application status
 * Implements the business logic for status-based task automation
 * @author Temitayo Oluwalade
 * @date 2024
 */
public with sharing class TaskCreationService {
    
    /**
     * @description Creates tasks for job applications based on their status
     * @param jobApplications List of Job Application records
     * @param oldMap Map of old Job Application records (null for insert)
     */
    public static void createTasksForStatusChange(List<Job_Application__c> jobApplications, Map<Id, Job_Application__c> oldMap) {
        List<Task> tasksToInsert = new List<Task>();
        
        for (Job_Application__c jobApp : jobApplications) {
            // Skip if this is an update and status hasn't changed
            if (oldMap != null && jobApp.Status__c == oldMap.get(jobApp.Id).Status__c) {
                continue;
            }
            
            List<Task> statusTasks = createTasksForStatus(jobApp);
            tasksToInsert.addAll(statusTasks);
        }
        
        // Bulk insert tasks
        if (!tasksToInsert.isEmpty()) {
            try {
                insert tasksToInsert;
            } catch (DmlException e) {
                System.debug('Error creating tasks: ' + e.getMessage());
                // In a real implementation, you might want to add error handling
                // that notifies users or logs the error appropriately
            }
        }
    }
    
    /**
     * @description Creates specific tasks based on job application status
     * @param jobApp Job Application record
     * @return List of Task records to be inserted
     */
    private static List<Task> createTasksForStatus(Job_Application__c jobApp) {
        List<Task> tasks = new List<Task>();
        
        switch on jobApp.Status__c {
            when 'Saved' {
                tasks.addAll(createSavedStatusTasks(jobApp));
            }
            when 'Applying' {
                tasks.addAll(createApplyingStatusTasks(jobApp));
            }
            when 'Applied' {
                tasks.addAll(createAppliedStatusTasks(jobApp));
            }
            when 'Interviewing' {
                tasks.addAll(createInterviewingStatusTasks(jobApp));
            }
            when 'Negotiating' {
                tasks.addAll(createNegotiatingStatusTasks(jobApp));
            }
            when 'Accepted' {
                tasks.addAll(createAcceptedStatusTasks(jobApp));
            }
            when 'Closed' {
                tasks.addAll(createClosedStatusTasks(jobApp));
            }
        }
        
        return tasks;
    }
    
    /**
     * @description Creates tasks for 'Saved' status
     */
    private static List<Task> createSavedStatusTasks(Job_Application__c jobApp) {
        List<Task> tasks = new List<Task>();
        
        tasks.add(createTask(
            'Check if the job description aligns with your interests and values',
            jobApp.Id,
            Date.today().addDays(1),
            'High'
        ));
        
        tasks.add(createTask(
            'Review the highlighted skills to see if the role is a good fit',
            jobApp.Id,
            Date.today().addDays(1),
            'High'
        ));
        
        tasks.add(createTask(
            'Research the company or role and mark your excitement level',
            jobApp.Id,
            Date.today().addDays(2),
            'Normal'
        ));
        
        return tasks;
    }
    
    /**
     * @description Creates tasks for 'Applying' status
     */
    private static List<Task> createApplyingStatusTasks(Job_Application__c jobApp) {
        List<Task> tasks = new List<Task>();
        
        tasks.add(createTask(
            'Find and research someone who works at the company and add them as a contact',
            jobApp.Id,
            Date.today().addDays(1),
            'High'
        ));
        
        tasks.add(createTask(
            'Set up an informational interview to learn more about the role/company',
            jobApp.Id,
            Date.today().addDays(3),
            'High'
        ));
        
        tasks.add(createTask(
            'Identify potential referrals to help get your application on the top of the pile',
            jobApp.Id,
            Date.today().addDays(2),
            'High'
        ));
        
        tasks.add(createTask(
            'Customize your work achievements using the job description keywords',
            jobApp.Id,
            Date.today().addDays(1),
            'High'
        ));
        
        tasks.add(createTask(
            'Submit your application on the company website if possible',
            jobApp.Id,
            Date.today().addDays(2),
            'High'
        ));
        
        return tasks;
    }
    
    /**
     * @description Creates tasks for 'Applied' status
     */
    private static List<Task> createAppliedStatusTasks(Job_Application__c jobApp) {
        List<Task> tasks = new List<Task>();
        
        tasks.add(createTask(
            'Reach out to the hiring manager or recruiter',
            jobApp.Id,
            Date.today().addDays(1),
            'High'
        ));
        
        tasks.add(createTask(
            'Follow up on your application via email weekly',
            jobApp.Id,
            Date.today().addDays(7),
            'Normal'
        ));
        
        tasks.add(createTask(
            'Continue identifying and saving similar job opportunities',
            jobApp.Id,
            Date.today().addDays(3),
            'Normal'
        ));
        
        tasks.add(createTask(
            'Set up weekly networking calls to explore similar companies/roles',
            jobApp.Id,
            Date.today().addDays(7),
            'Normal'
        ));
        
        return tasks;
    }

    /**
     * @description Creates tasks for 'Interviewing' status
     */
    private static List<Task> createInterviewingStatusTasks(Job_Application__c jobApp) {
        List<Task> tasks = new List<Task>();

        tasks.add(createTask(
            'Prepare your blurb or "tell me about yourself" response',
            jobApp.Id,
            Date.today().addDays(1),
            'High'
        ));

        tasks.add(createTask(
            'Practice answering behavioral interview questions',
            jobApp.Id,
            Date.today().addDays(1),
            'High'
        ));

        tasks.add(createTask(
            'Research the company and your interviewers',
            jobApp.Id,
            Date.today().addDays(1),
            'High'
        ));

        tasks.add(createTask(
            'Set up your virtual interview space and test your tech',
            jobApp.Id,
            Date.today().addDays(1),
            'High'
        ));

        tasks.add(createTask(
            'Send thank you emails within 24 hours',
            jobApp.Id,
            Date.today().addDays(2),
            'High'
        ));

        return tasks;
    }

    /**
     * @description Creates tasks for 'Negotiating' status
     */
    private static List<Task> createNegotiatingStatusTasks(Job_Application__c jobApp) {
        List<Task> tasks = new List<Task>();

        tasks.add(createTask(
            'Research your market value and know your numbers',
            jobApp.Id,
            Date.today().addDays(1),
            'High'
        ));

        tasks.add(createTask(
            'Prepare your negotiation scripts',
            jobApp.Id,
            Date.today().addDays(1),
            'High'
        ));

        tasks.add(createTask(
            'Evaluate your offer and decline or accept',
            jobApp.Id,
            Date.today().addDays(3),
            'High'
        ));

        return tasks;
    }

    /**
     * @description Creates tasks for 'Accepted' status
     */
    private static List<Task> createAcceptedStatusTasks(Job_Application__c jobApp) {
        List<Task> tasks = new List<Task>();

        tasks.add(createTask(
            'Plan your resignation if applicable',
            jobApp.Id,
            Date.today().addDays(1),
            'High'
        ));

        tasks.add(createTask(
            'Take some time to relax and recharge',
            jobApp.Id,
            Date.today().addDays(1),
            'Low'
        ));

        tasks.add(createTask(
            'Prepare for your first day of onboarding',
            jobApp.Id,
            Date.today().addDays(7),
            'Normal'
        ));

        return tasks;
    }

    /**
     * @description Creates tasks for 'Closed' status
     */
    private static List<Task> createClosedStatusTasks(Job_Application__c jobApp) {
        List<Task> tasks = new List<Task>();

        tasks.add(createTask(
            'Send a follow-up email thanking the interviewer and asking for feedback',
            jobApp.Id,
            Date.today().addDays(1),
            'Normal'
        ));

        tasks.add(createTask(
            'Review your notes and reflect on areas of improvement',
            jobApp.Id,
            Date.today().addDays(2),
            'Normal'
        ));

        return tasks;
    }

    /**
     * @description Helper method to create a task record
     * @param subject Task subject
     * @param whatId Related Job Application Id
     * @param dueDate Task due date
     * @param priority Task priority
     * @return Task record
     */
    private static Task createTask(String subject, Id whatId, Date dueDate, String priority) {
        return new Task(
            Subject = subject,
            WhatId = whatId,
            ActivityDate = dueDate,
            Priority = priority,
            Status = 'Not Started',
            Description = 'Auto-generated task based on Job Application status change'
        );
    }
}
