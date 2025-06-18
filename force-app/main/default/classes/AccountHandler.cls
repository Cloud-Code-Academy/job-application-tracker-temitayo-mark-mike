public class AccountHandler {
    public static void insertAccount(Integer value){
        Integer N = 1;
        List<Account> addAccounts = new List<Account>();
        while(N <= value){
            Account act = new Account();
            act.Name = 'Acme Inc ' + N;
            act.AccountNumber = 'A000' + N;
            addAccounts.add(act);
            N = N + 1;
        }
        insert addAccounts;
    }
}