trigger PreventContactDelete on Contact (before delete) {
    for (Contact con : Trigger.old) {
        if (con.Id == '003ak00000TZk2TAAT') {
            con.addError('This Contact record cannot be deleted.');
        }
    }
}