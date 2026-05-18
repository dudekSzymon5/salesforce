@IsTest
private class ProductSyncSoftDeleteControllerTest {

    @TestSetup
    static void makeData() {
        TriggerBase.bypass('Product2');

        TestDataFactory.product().withCode('TP-01').create();
        TestDataFactory.product().withCode('TP-02').deleted().create();
        TriggerBase.clearBypass('Product2');
    }

    @IsTest
    static void testSoftDeleteFlag() {
        Product2 product = [
                SELECT Id
                FROM Product2
                WHERE ProductCode = 'TP-01'
            ];
        Test.startTest();
        ProductSyncSoftDeleteController.softDeleteProduct(product.Id);
        Test.stopTest();

        Product2 result = [
                SELECT Id, Is_Deleted__c
                FROM Product2
                WHERE ProductCode = 'TP-01'
            ];
        Assert.areEqual(true, result.Is_Deleted__c);
    } 

    @IsTest
    static void testSoftDeleteIsAlreadyDeleted() {
        Product2 product = [
                SELECT Id 
                FROM Product2 
                WHERE ProductCode = 'TP-02'
            ];

        Test.startTest();
        try {
            ProductSyncSoftDeleteController.softDeleteProduct(product.Id);
            Assert.fail('Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.areEqual('Product is already deleted', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testSoftDeleteBadId() {
        Id fakeId = '11apex000000000SZY';

        Test.startTest();
        try {
            ProductSyncSoftDeleteController.softDeleteProduct(fakeId);
            Assert.fail('Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage());
        }
        Test.stopTest();
    }
}
