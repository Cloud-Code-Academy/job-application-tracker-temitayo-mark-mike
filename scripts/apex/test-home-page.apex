try {
    Map<String, Object> result = ApplicationAnalyticsService.getApplicationAnalytics();
    System.debug('SUCCESS: ' + JSON.serialize(result));
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage() + ' | ' + e.getStackTraceString());
}
