/**
 * @description Test data factory for Interview Feedback related objects
 * @author System Generated
 * @date 2024
 */
@IsTest
public inherited sharing class InterviewFeedbackTestDataFactory {
    
    /**
     * @description Create a test Job Application record
     * @param companyName Company name for the job application
     * @param positionTitle Position title
     * @param status Application status
     * @return Job_Application__c record
     */
    public static Job_Application__c createJobApplication(String companyName, String positionTitle, String status) {
        return new Job_Application__c(
            Company_Name__c = companyName,
            Position_Title__c = positionTitle,
            Status__c = status,
            Application_Date__c = Date.today().addDays(-30),
            Job_Description__c = 'Test job description for software engineering position',
            Location__c = 'Remote',
            Salary__c = 120000,
            Employment_Type__c = 'Full-time'
        );
    }
    
    /**
     * @description Create a test Job Application record with default values
     * @return Job_Application__c record
     */
    public static Job_Application__c createJobApplication() {
        return createJobApplication('Test Company', 'Software Engineer', 'Applied');
    }
    
    /**
     * @description Create multiple Job Application records
     * @param count Number of records to create
     * @return List of Job_Application__c records
     */
    public static List<Job_Application__c> createJobApplications(Integer count) {
        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        for (Integer i = 0; i < count; i++) {
            jobApps.add(createJobApplication('Test Company ' + i, 'Position ' + i, 'Applied'));
        }
        return jobApps;
    }
    
    /**
     * @description Create a test Interview Feedback record
     * @param jobApplicationId Related Job Application ID
     * @param interviewType Type of interview
     * @param overallRating Overall rating
     * @param interviewDate Interview date
     * @return Interview_Feedback__c record
     */
    public static Interview_Feedback__c createInterviewFeedback(Id jobApplicationId, String interviewType, Decimal overallRating, DateTime interviewDate) {
        return new Interview_Feedback__c(
            Job_Application__c = jobApplicationId,
            Interview_Type__c = interviewType,
            Interview_Date__c = interviewDate,
            Overall_Rating__c = overallRating,
            Technical_Rating__c = overallRating,
            Communication_Rating__c = overallRating,
            Cultural_Fit_Rating__c = overallRating,
            Interviewer_Name__c = 'Test Interviewer',
            Interviewer_Email__c = 'interviewer@test.com',
            Duration_Minutes__c = 60,
            Detailed_Feedback__c = 'Test detailed feedback',
            Strengths__c = 'Strong technical skills',
            Areas_For_Improvement__c = 'Communication could be improved',
            Recommendation__c = 'Hire',
            Feedback_Status__c = 'Submitted',
            Feedback_Source__c = 'Interviewer'
        );
    }
    
    /**
     * @description Create a test Interview Feedback record with default values
     * @param jobApplicationId Related Job Application ID
     * @return Interview_Feedback__c record
     */
    public static Interview_Feedback__c createInterviewFeedback(Id jobApplicationId) {
        return createInterviewFeedback(jobApplicationId, 'Technical', 4.0, DateTime.now().addDays(-1));
    }
    
    /**
     * @description Create multiple Interview Feedback records
     * @param jobApplicationIds List of Job Application IDs
     * @param countPerJob Number of feedback records per job application
     * @return List of Interview_Feedback__c records
     */
    public static List<Interview_Feedback__c> createInterviewFeedbacks(List<Id> jobApplicationIds, Integer countPerJob) {
        List<Interview_Feedback__c> feedbacks = new List<Interview_Feedback__c>();
        for (Id jobAppId : jobApplicationIds) {
            for (Integer i = 0; i < countPerJob; i++) {
                feedbacks.add(createInterviewFeedback(jobAppId, 'Technical', 3.0 + i, DateTime.now().addDays(-i)));
            }
        }
        return feedbacks;
    }
    
    /**
     * @description Create a test Feedback Template record
     * @param templateName Template name
     * @param interviewType Interview type
     * @param competencyAreas List of competency areas
     * @param ratingScale Rating scale
     * @return Feedback_Template__c record
     */
    public static Feedback_Template__c createFeedbackTemplate(String templateName, String interviewType, List<String> competencyAreas, String ratingScale) {
        return new Feedback_Template__c(
            Template_Name__c = templateName,
            Interview_Type__c = interviewType,
            Competency_Areas__c = String.join(competencyAreas, ';'),
            Rating_Scale__c = ratingScale,
            Template_Description__c = 'Test template description',
            Form_Configuration__c = '{"fields": ["technical", "communication"]}',
            Is_Active__c = true,
            Usage_Count__c = 0,
            Created_By_Role__c = 'Manager'
        );
    }
    
    /**
     * @description Create a test Feedback Template record with default values
     * @return Feedback_Template__c record
     */
    public static Feedback_Template__c createFeedbackTemplate() {
        return createFeedbackTemplate('Technical Interview Template', 'Technical', 
                                    new List<String>{'Technical Skills', 'Problem Solving'}, '1-5');
    }
    
    /**
     * @description Create multiple Feedback Template records
     * @param count Number of templates to create
     * @return List of Feedback_Template__c records
     */
    public static List<Feedback_Template__c> createFeedbackTemplates(Integer count) {
        List<Feedback_Template__c> templates = new List<Feedback_Template__c>();
        for (Integer i = 0; i < count; i++) {
            templates.add(createFeedbackTemplate('Template ' + i, 'Technical', 
                                               new List<String>{'Skill ' + i}, '1-5'));
        }
        return templates;
    }
    
    /**
     * @description Create multiple default Feedback Template records
     * @return List of Feedback_Template__c records
     */
    public static List<Feedback_Template__c> createFeedbackTemplates() {
        return createFeedbackTemplates(3);
    }
    
    /**
     * @description Create Competency Rating records
     * @param feedbackId Related Interview Feedback ID
     * @param competencyNames List of competency names
     * @return List of Competency_Rating__c records
     */
    public static List<Competency_Rating__c> createCompetencyRatings(Id feedbackId, List<String> competencyNames) {
        List<Competency_Rating__c> ratings = new List<Competency_Rating__c>();
        for (String competency : competencyNames) {
            ratings.add(new Competency_Rating__c(
                Interview_Feedback__c = feedbackId,
                Competency_Name__c = competency,
                Rating__c = 4.0,
                Comments__c = 'Good performance in ' + competency,
                Weight__c = 1.0
            ));
        }
        return ratings;
    }
    
    /**
     * @description Create a Feedback Share record
     * @param feedbackId Related Interview Feedback ID
     * @param sharedWithEmail Email to share with
     * @param accessLevel Access level
     * @param expirationDate Expiration date
     * @return Feedback_Share__c record
     */
    public static Feedback_Share__c createFeedbackShare(Id feedbackId, String sharedWithEmail, String accessLevel, DateTime expirationDate) {
        return new Feedback_Share__c(
            Interview_Feedback__c = feedbackId,
            Shared_With_Email__c = sharedWithEmail,
            Access_Level__c = accessLevel,
            Expiration_Date__c = expirationDate,
            Share_Token__c = 'test-token-' + String.valueOf(Math.random()),
            Share_Message__c = 'Please review this interview feedback',
            Is_Active__c = true,
            Access_Count__c = 0
        );
    }
    
    /**
     * @description Create test users with different permission levels
     * @param count Number of users to create
     * @return List of User records
     */
    public static List<User> createTestUsers(Integer count) {
        List<User> users = new List<User>();
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        for (Integer i = 0; i < count; i++) {
            users.add(new User(
                FirstName = 'Test',
                LastName = 'User' + i,
                Email = 'testuser' + i + '@test.com',
                Username = 'testuser' + i + '@test.com.test',
                Alias = 'tuser' + i,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = standardProfile.Id
            ));
        }
        return users;
    }
}