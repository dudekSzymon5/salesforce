@IsTest
private class ApprovalSyncQueueableTest {

    private static final String SUCCESS_BODY = '{"id":"e02xx0000000001AAA","success":true,"errors":[]}';

    @IsTest
    static void testApprovalSyncSuccess() {
        Test.setMock(HttpCalloutMock.class, new TestDataFactory.HttpMock(200, SUCCESS_BODY));

        Test.startTest();
        System.enqueueJob(new ApprovalSyncQueueable (
                'test-correlation-id',
                Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.APPROVED_FULL,
                100.00,
                Utils.ORDER_COMPLAINT.REFUND_TYPE.FULL,
                null
        ));
        Test.stopTest();
    }

    @IsTest
    static void testApprovalSyncError() {
        Test.setMock(HttpCalloutMock.class, new TestDataFactory.HttpMock(500, '{"error":"Internal Server Error"}'));

        Test.startTest();
        System.enqueueJob(new ApprovalSyncQueueable (
                'test-correlation-id',
                Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.REJECTED,
                0,
                Utils.ORDER_COMPLAINT.REFUND_TYPE.REJECTED,
                null
        ));
        Test.stopTest();
    }
}
