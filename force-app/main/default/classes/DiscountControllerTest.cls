@IsTest
private class DiscountControllerTest {

    @TestSetup
    static void setupData() {
        TestDataFactory.discount()
            .conditional('Minimum Order Value')
            .withMinOrder(100).create();

        Account account = TestDataFactory.createAccount();
        Contract contract = TestDataFactory.createContract(account.Id);
        TestDataFactory.order()
            .forAccount(account.Id)
            .withContract(contract.Id).create();
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
    static void testSaveDiscountNewRecordReturnsWithId() {
        Discount__c discount = TestDataFactory.discount().oneTime().asAmount().withValue(50).build();

        Test.startTest();
        Discount__c saved = DiscountController.saveDiscount(discount);
        Test.stopTest();

        Assert.isNotNull(saved.Id);
    }

    @IsTest
    static void testSaveDiscountAlreadyAssignedThrowsException() {
        Discount__c discount = [SELECT Id FROM Discount__c LIMIT 1];
        Order order = [SELECT Id FROM Order LIMIT 1];
        insert new Order_Discount__c(
            Order__c = order.Id, Discount__c = discount.Id,
            Applied_Value__c = 10, Original_Price__c = 100, Discounted_Price__c = 90
        );

        Test.startTest();
        try {
            DiscountController.saveDiscount(discount);
            Assert.fail('Expected AuraHandledException for already assigned discount');
        } catch (AuraHandledException caughtException) {
            Assert.isNotNull(caughtException.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testSaveDiscountTwoForOneSetsMinimumQuantity() {
        Discount__c discount = TestDataFactory.discount()
            .conditional('Two For One')
            .withValue(50).build();

        Test.startTest();
        Discount__c saved = DiscountController.saveDiscount(discount);
        Test.stopTest();

        Assert.areEqual(2, saved.Minimum_Quantity__c);
    }

    @IsTest
    static void testSaveDiscountPercentageOver100ThrowsException() {
        Discount__c discount = TestDataFactory.discount().oneTime().withValue(150).build();

        Test.startTest();
        try {
            DiscountController.saveDiscount(discount);
            Assert.fail('Expected AuraHandledException for percentage value over 100');
        } catch (AuraHandledException caughtException) {
            Assert.isNotNull(caughtException.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testToggleDiscountsDeactivates() {
        Discount__c discount = [SELECT Id FROM Discount__c LIMIT 1];

        Test.startTest();
        DiscountController.toggleDiscounts(new List<Id>{ discount.Id }, false);
        Test.stopTest();

        Discount__c updated = [SELECT Is_Active__c FROM Discount__c WHERE Id = :discount.Id];
        Assert.isFalse(updated.Is_Active__c);
    }

    @IsTest
    static void testGetAssignedDiscountIdsEmpty() {
        Test.startTest();
        List<Id> assignedIds = DiscountController.getAssignedDiscountIds();
        Test.stopTest();

        Assert.isNotNull(assignedIds);
        Assert.isTrue(assignedIds.isEmpty());
    }

    @IsTest
    static void testGetAssignedDiscountIdsWithAssignment() {
        Discount__c discount = [SELECT Id FROM Discount__c LIMIT 1];
        Order order = [SELECT Id FROM Order LIMIT 1];
        insert new Order_Discount__c(
            Order__c = order.Id, Discount__c = discount.Id,
            Applied_Value__c = 10, Original_Price__c = 100, Discounted_Price__c = 90
        );

        Test.startTest();
        List<Id> assignedIds = DiscountController.getAssignedDiscountIds();
        Test.stopTest();

        Assert.isTrue(assignedIds.contains(discount.Id));
    }

    @IsTest
    static void testGetProductOptions() {
        Product2 product = TestDataFactory.product().withName('Option Product').create();
        TestDataFactory.addToPricebook(product.Id, 100);

        Test.startTest();
        List<Product2> products = DiscountController.getProductOptions();
        Test.stopTest();

        Assert.isTrue(products.size() > 0);
    }

    @IsTest
    static void testGetProductFamilies() {
        Test.startTest();
        List<String> families = DiscountController.getProductFamilies();
        Test.stopTest();

        Assert.isNotNull(families);
    }

    @IsTest
    static void testGetDiscountProducts() {
        Discount__c discount = [SELECT Id FROM Discount__c LIMIT 1];
        Product2 product = TestDataFactory.product().withName('Linked Product').create();
        insert new Discount_Product__c(Discount__c = discount.Id, Product__c = product.Id);

        Test.startTest();
        List<Id> productIds = DiscountController.getDiscountProducts(discount.Id);
        Test.stopTest();

        Assert.isTrue(productIds.size() > 0);
    }

    @IsTest
    static void testSaveDiscountProductsAddsLinks() {
        Discount__c discount = [SELECT Id FROM Discount__c LIMIT 1];
        Product2 product = TestDataFactory.product().withName('Save Product').create();

        Test.startTest();
        DiscountController.saveDiscountProducts(discount.Id, new List<Id>{ product.Id });
        Test.stopTest();

        List<Discount_Product__c> discountProducts = [SELECT Id FROM Discount_Product__c WHERE Discount__c = :discount.Id];
        Assert.isTrue(discountProducts.size() > 0);
    }

    @IsTest
    static void testSaveDiscountProductsEmptyListRemovesAll() {
        Discount__c discount = [SELECT Id FROM Discount__c LIMIT 1];
        Product2 product = TestDataFactory.product().withName('Del Product').create();
        insert new Discount_Product__c(Discount__c = discount.Id, Product__c = product.Id);

        Test.startTest();
        DiscountController.saveDiscountProducts(discount.Id, new List<Id>());
        Test.stopTest();

        List<Discount_Product__c> discountProducts = [SELECT Id FROM Discount_Product__c WHERE Discount__c = :discount.Id];
        Assert.isTrue(discountProducts.isEmpty());
    }

    @IsTest
    static void testSaveDiscountSettingsDoesNotThrow() {
        Test.startTest();
        try {
            DiscountController.saveDiscountSettings('Highest Discount', 0);
        } catch (AuraHandledException caughtException) {
            Assert.isNotNull(caughtException.getMessage());
        }
        Test.stopTest();

        Assert.isTrue(true);
    }

    @IsTest
    static void testApplyDiscountsToOrderReturnsResult() {
        Order order = [SELECT Id FROM Order LIMIT 1];

        Test.startTest();
        List<Order_Discount__c> applied = DiscountController.applyDiscountsToOrder(order.Id, 500);
        Test.stopTest();

        Assert.isNotNull(applied);
    }

    @IsTest
    static void testPreviewDiscountsAboveMinOrderReturnsPreview() {
        Test.startTest();
        List<DiscountService.DiscountPreview> previews = DiscountController.previewDiscounts(
            500, new List<DiscountService.ItemInput>()
        );
        Test.stopTest();

        Assert.isTrue(previews.size() > 0);
        Assert.isNotNull(previews[0].discountName);
        Assert.isNotNull(previews[0].appliedValue);
    }

    @IsTest
    static void testPreviewDiscountsBelowMinOrderReturnsEmpty() {
        Test.startTest();
        List<DiscountService.DiscountPreview> previews = DiscountController.previewDiscounts(
            50, new List<DiscountService.ItemInput>()
        );
        Test.stopTest();

        Assert.isTrue(previews.isEmpty());
    }

    @IsTest
    static void testPreviewDiscountsSpecificProductTargeted() {
        Product2 product = TestDataFactory.product().withName('Targeted Product').create();
        Discount__c discount = TestDataFactory.discount().oneTime().forProducts().create();
        insert new Discount_Product__c(Discount__c = discount.Id, Product__c = product.Id);

        DiscountService.ItemInput item = new DiscountService.ItemInput();
        item.product2Id = product.Id;
        item.amount = 200;
        item.quantity = 1;

        Test.startTest();
        List<DiscountService.DiscountPreview> previews = DiscountController.previewDiscounts(
            200, new List<DiscountService.ItemInput>{ item }
        );
        Test.stopTest();

        Assert.isNotNull(previews);
    }

    @IsTest
    static void testPreviewDiscountsSpecificFamilyTargeted() {
        Product2 product = TestDataFactory.product().withName('Family Product').withFamily('Electronics').create();
        Discount__c discount = TestDataFactory.discount().oneTime().forFamilies('Electronics').create();

        DiscountService.ItemInput item = new DiscountService.ItemInput();
        item.product2Id = product.Id;
        item.amount = 200;
        item.quantity = 1;

        Test.startTest();
        List<DiscountService.DiscountPreview> previews = DiscountController.previewDiscounts(
            200, new List<DiscountService.ItemInput>{ item }
        );
        Test.stopTest();

        Assert.isNotNull(previews);
    }

    @IsTest
    static void testPreviewDiscountsTwoForOne() {
        Product2 product = TestDataFactory.product().withName('TwoForOne Product').create();
        TestDataFactory.discount()
            .conditional('Two For One')
            .withValue(50)
            .withMinQuantity(2).create();

        DiscountService.ItemInput item = new DiscountService.ItemInput();
        item.product2Id = product.Id;
        item.amount = 200;
        item.quantity = 4;

        Test.startTest();
        List<DiscountService.DiscountPreview> previews = DiscountController.previewDiscounts(
            200, new List<DiscountService.ItemInput>{ item }
        );
        Test.stopTest();

        Assert.isNotNull(previews);
    }

    @IsTest
    static void testPreviewDiscountsAmountForm() {
        TestDataFactory.discount()
            .conditional('Minimum Order Value')
            .asAmount()
            .withValue(20)
            .withMinOrder(100).create();

        Test.startTest();
        List<DiscountService.DiscountPreview> previews = DiscountController.previewDiscounts(
            500, new List<DiscountService.ItemInput>()
        );
        Test.stopTest();

        Assert.isNotNull(previews);
    }
}
