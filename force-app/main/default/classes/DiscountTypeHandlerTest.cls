@IsTest
private class DiscountTypeHandlerTest {

    @IsTest
    static void testForTypeReturnsRecurringHandler() {
        DiscountTypeHandler handler = DiscountTypeHandler.forType('Recurring');
        Assert.isTrue(handler instanceof RecurringDiscountHandler);
    }

    @IsTest
    static void testForTypeReturnsConditionalHandler() {
        DiscountTypeHandler handler = DiscountTypeHandler.forType('Conditional');
        Assert.isTrue(handler instanceof ConditionalDiscountHandler);
    }

    @IsTest
    static void testForTypeReturnsOneTimeHandler() {
        DiscountTypeHandler handler = DiscountTypeHandler.forType('One-Time');
        Assert.isTrue(handler instanceof OneTimeDiscountHandler);
    }

    @IsTest
    static void testForTypeUnknownTypeDefaultsToOneTime() {
        DiscountTypeHandler handler = DiscountTypeHandler.forType('Unknown');
        Assert.isTrue(handler instanceof OneTimeDiscountHandler);
    }

    @IsTest
    static void testIsApplicableTargetAllNoProductsReturnsTrue() {
        Discount__c discount = TestDataFactory.aDiscount().build();

        Boolean result = new OneTimeDiscountHandler().isApplicable(
            discount, 100, Date.today(), new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null
        );
        // Poprzenosić do TESTSETUP'u
        // Zadbać w kolejce o to, że jak pobieram produkt to żeby nikt ich nie zmienił
        //
        Assert.isTrue(result);
    }

    @IsTest
    static void testIsApplicableTargetProductsNoLinkedProductsReturnsFalse() {
        Discount__c discount = TestDataFactory.aDiscount().forProducts().build();
        Product2 product = TestDataFactory.aProduct().withName('P1').create();

        Boolean result = new OneTimeDiscountHandler().isApplicable(
            discount, 100, Date.today(),
            new Set<Id>{ product.Id },
            new Map<Id, Decimal>{ product.Id => 1 },
            new Map<Id, String>(),
            null
        );

        Assert.isFalse(result);
    }

    @IsTest
    static void testIsApplicableTargetProductsProductInOrderAndLinkedReturnsTrue() {
        Discount__c discount = TestDataFactory.aDiscount().forProducts().build();
        Product2 product = TestDataFactory.aProduct().withName('P1').create();
        Set<Id> productIds = new Set<Id>{ product.Id };

        Boolean result = new OneTimeDiscountHandler().isApplicable(
            discount, 100, Date.today(),
            productIds,
            new Map<Id, Decimal>{ product.Id => 1 },
            new Map<Id, String>(),
            productIds
        );

        Assert.isTrue(result);
    }

    @IsTest
    static void testIsApplicableTargetProductsLinkedButNotInOrderReturnsFalse() {
        Discount__c discount = TestDataFactory.aDiscount().forProducts().build();
        Product2 product1 = TestDataFactory.aProduct().withName('P1').withCode('P1').create();
        Product2 product2 = TestDataFactory.aProduct().withName('P2').withCode('P2').create();

        Boolean result = new OneTimeDiscountHandler().isApplicable(
            discount, 100, Date.today(),
            new Set<Id>{ product1.Id },
            new Map<Id, Decimal>{ product1.Id => 1 },
            new Map<Id, String>(),
            new Set<Id>{ product2.Id }
        );

        Assert.isFalse(result);
    }

    @IsTest
    static void testIsApplicableTargetFamiliesNullFamiliesReturnsFalse() {
        Discount__c discount = TestDataFactory.aDiscount().build();
        discount.Target_Application__c = 'Specific Families';
        discount.Target_Families__c = null;
        Product2 product = TestDataFactory.aProduct().withName('P1').withFamily('Electronics').create();

        Boolean result = new OneTimeDiscountHandler().isApplicable(
            discount, 100, Date.today(),
            new Set<Id>{ product.Id },
            new Map<Id, Decimal>{ product.Id => 1 },
            new Map<Id, String>{ product.Id => 'Electronics' },
            null
        );

        Assert.isFalse(result);
    }

    @IsTest
    static void testIsApplicableTargetFamiliesNoMatchReturnsFalse() {
        Discount__c discount = TestDataFactory.aDiscount().forFamilies('Electronics').build();
        Product2 product = TestDataFactory.aProduct().withName('P1').withFamily('Software').create();

        Boolean result = new OneTimeDiscountHandler().isApplicable(
            discount, 100, Date.today(),
            new Set<Id>{ product.Id },
            new Map<Id, Decimal>{ product.Id => 1 },
            new Map<Id, String>{ product.Id => 'Software' },
            null
        );

        Assert.isFalse(result);
    }

    @IsTest
    static void testIsApplicableTargetFamiliesMatchesReturnsTrue() {
        Discount__c discount = TestDataFactory.aDiscount().forFamilies('Electronics').build();
        Product2 product = TestDataFactory.aProduct().withName('P1').withFamily('Electronics').create();

        Boolean result = new OneTimeDiscountHandler().isApplicable(
            discount, 100, Date.today(),
            new Set<Id>{ product.Id },
            new Map<Id, Decimal>{ product.Id => 1 },
            new Map<Id, String>{ product.Id => 'Electronics' },
            null
        );

        Assert.isTrue(result);
    }

    @IsTest
    static void testIsApplicableMinimumQuantityNotMetReturnsFalse() {
        Discount__c discount = TestDataFactory.aDiscount().withMinQuantity(5).build();
        Product2 product = TestDataFactory.aProduct().withName('P1').create();

        Boolean result = new OneTimeDiscountHandler().isApplicable(
            discount, 100, Date.today(),
            new Set<Id>{ product.Id },
            new Map<Id, Decimal>{ product.Id => 2 },
            new Map<Id, String>(),
            null
        );

        Assert.isFalse(result);
    }

    @IsTest
    static void testIsApplicableMinimumQuantityMetReturnsTrue() {
        Discount__c discount = TestDataFactory.aDiscount().withMinQuantity(5).build();
        Product2 product = TestDataFactory.aProduct().withName('P1').create();

        Boolean result = new OneTimeDiscountHandler().isApplicable(
            discount, 100, Date.today(),
            new Set<Id>{ product.Id },
            new Map<Id, Decimal>{ product.Id => 10 },
            new Map<Id, String>(),
            null
        );

        Assert.isTrue(result);
    }
}
