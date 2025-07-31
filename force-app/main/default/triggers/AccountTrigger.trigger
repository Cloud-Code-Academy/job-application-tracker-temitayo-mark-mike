trigger AccountTrigger on Account (after insert) {
    new AccountTriggerHandler().run();
}