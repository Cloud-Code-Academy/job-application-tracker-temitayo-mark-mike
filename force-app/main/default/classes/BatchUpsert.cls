public class BatchUpsert implements Database.Batchable<SObject>, Database.Stateful {
    public List <SObject> records = new List<SObject>();
    public Integer successfulCount = 0;
    public Integer errorCount = 0;
    public Integer position = 0;
    public Boolean sendEmail = true;
    public String batchName = UserInfo.getUserName() + ' ' + String.valueOf(System.now());

    public BatchUpsert(List<SObject> records){
        this.records = records;
    }

    public BatchUpsert(List<SObject> records, Boolean sendEmail){
        this.records = records;
        this.sendEmail = sendEmail;
    }

    public BatchUpsert(List<SObject> records, String batchName, Boolean sendEmail){
        this.records = records;
        this.sendEmail = sendEmail;
        this.batchName = batchName;
    }

    public List<SObject> start(Database.BatchableContext bc) {
        return records;
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope){
        Database.UpsertResult[] urList = Database.upsert(scope, false);

        for (Database.UpsertResult ur : urList) {
            if (ur.isSuccess()) {
                successfulCount++;
            }
            else {
                for(Database.Error err : ur.getErrors()) {
                    System.debug('BatchUpsert Error\NRecord ID: ' + records[position].Id + '\NStatus Code: ' + err.getStatusCode() + '\NError Message: ' + err.getMessage() + '\NAffected Fields: ' + err.getFields());
                    errorCount++;
                }
            }
            position++;
        }
    }

    public void finish(Database.BatchableContext bc){
        if(sendEmail) {
            String subject = 'Batch Upsert Results - ' + batchName;
            String body = 'Batch Name: ' + batchName + 'Batch ID: '+ bc.getJobId() + '\N\NTimestamp: ' + System.now() + '\N\N' + successfulCount +' Records Upserted.\N\N' + errorCount + ' Failures.';
            //Utilities.sendErrorEmail(subject, body);
        }
    }
}