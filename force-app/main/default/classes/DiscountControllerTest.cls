@IsTest
private class DiscountControllerTest {

    @TestSetup
    static void setupData() {
        Discount__c discount = new Discount__c(
            Name='Test Discount',
            Type__c='Conditional',
            Discount_Form__c='Percentage',
            Value__c=10,
            Is_Active__c=true,
            Minimum_Order_Amount__c=100
        );
        insert discount;

        Account acc = new Account(Name='Test Account');
        insert acc;

        Contract con = new Contract(
            AccountId=acc.Id,
            StartDate=Date.today(),
            ContractTerm=12,
            Status='Draft'
        );
        insert con;
        con.Status = 'Activated';
        update con;

        Order ord = new Order(
            AccountId=acc.Id,
            ContractId=con.Id,
            Status='Draft',
            EffectiveDate=Date.today(),
            Pricebook2Id=Test.getStandardPricebookId()
        );
        insert ord;
    }

    @IsTest
    static void testGetDiscounts() {
        Test.startTest();
        List<Discount__c> discounts = DiscountController.getDiscounts();
        Test.stopTest();

        Assert.isNotNull(discounts);
        Assert.isTrue(discounts.size() > 0);
    }

    @IsTest
    static void testGetDiscountSettings() {
        Test.startTest();
        Discount_Settings__mdt settings = DiscountController.getDiscountSettings();
        Test.stopTest();

        Assert.isNotNull(settings);
    }

    @IsTest
    static void testSaveDiscount() {
        Discount__c discount = new Discount__c(
            Name='New Discount',
            Type__c='One-Time',
            Discount_Form__c='Amount',
            Value__c=50,
            Is_Active__c=true
        );

        Test.startTest();
        Discount__c saved = DiscountController.saveDiscount(discount);
        Test.stopTest();

        Assert.isNotNull(saved.Id);
    }

    @IsTest
    static void testSaveDiscountAssigned() {
        Discount__c discount = [SELECT Id FROM Discount__c LIMIT 1];
        Order ord = [SELECT Id FROM Order LIMIT 1];

        Order_Discount__c od = new Order_Discount__c(
            Order__c=ord.Id,
            Discount__c=discount.Id,
            Applied_Value__c=10,
            Original_Price__c=100,
            Discounted_Price__c=90
        );
        insert od;

        Test.startTest();
        try {
            DiscountController.saveDiscount(discount);
            Assert.fail('Should have thrown exception');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetAssignedDiscountIds_empty() {
        Test.startTest();
        List<Id> ids = DiscountController.getAssignedDiscountIds();
        Test.stopTest();

        Assert.isNotNull(ids);
        Assert.isTrue(ids.isEmpty());
    }

    @IsTest
    static void testGetAssignedDiscountIds_withAssignment() {
        Discount__c discount = [SELECT Id FROM Discount__c LIMIT 1];
        Order ord = [SELECT Id FROM Order LIMIT 1];

        insert new Order_Discount__c(
            Order__c=ord.Id,
            Discount__c=discount.Id,
            Applied_Value__c=10,
            Original_Price__c=100,
            Discounted_Price__c=90
        );

        Test.startTest();
        List<Id> ids = DiscountController.getAssignedDiscountIds();
        Test.stopTest();

        Assert.isTrue(ids.contains(discount.Id));
    }

    @IsTest
    static void testToggleDiscounts() {
        Discount__c discount = [SELECT Id FROM Discount__c LIMIT 1];

        Test.startTest();
        DiscountController.toggleDiscounts(new List<Id>{ discount.Id }, false);
        Test.stopTest();

        Discount__c updated = [SELECT Is_Active__c FROM Discount__c WHERE Id = :discount.Id];
        Assert.isFalse(updated.Is_Active__c);
    }

    @IsTest
    static void testApplyDiscountsToOrder() {
        Order ord = [SELECT Id FROM Order LIMIT 1];

        Test.startTest();
        List<Order_Discount__c> applied = DiscountController.applyDiscountsToOrder(ord.Id, 500);
        Test.stopTest();

        Assert.isNotNull(applied);
    }

    @IsTest
    static void testPreviewDiscountsWithApplicable() {
        Test.startTest();
        List<DiscountService.DiscountPreview> previews = DiscountController.previewDiscounts(500, new List<DiscountService.ItemInput>());
        Test.stopTest();

        Assert.isNotNull(previews);
        Assert.isTrue(previews.size() > 0);
        Assert.isNotNull(previews[0].discountName);
        Assert.isNotNull(previews[0].appliedValue);
        Assert.isNotNull(previews[0].originalPrice);
        Assert.isNotNull(previews[0].discountedPrice);
    }

    @IsTest
    static void testPreviewDiscountsNoApplicable() {
        Test.startTest();
        List<DiscountService.DiscountPreview> previews = DiscountController.previewDiscounts(50, new List<DiscountService.ItemInput>());
        Test.stopTest();

        Assert.isNotNull(previews);
        Assert.isTrue(previews.isEmpty());
    }
}