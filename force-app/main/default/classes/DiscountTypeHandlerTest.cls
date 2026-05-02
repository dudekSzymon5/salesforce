@IsTest
private class DiscountTypeHandlerTest {

    static Discount__c makeDiscount(String type) {
        return new Discount__c(
            Name = 'Test',
            Type__c = type,
            Discount_Form__c = 'Percentage',
            Value__c = 10,
            Is_Active__c = true
        );
    }

    @IsTest
    static void testForType_returnsRecurringHandler() {
        DiscountTypeHandler handler = DiscountTypeHandler.forType('Recurring');
        Assert.isTrue(handler instanceof RecurringDiscountHandler);
    }

    @IsTest
    static void testForType_returnsConditionalHandler() {
        DiscountTypeHandler handler = DiscountTypeHandler.forType('Conditional');
        Assert.isTrue(handler instanceof ConditionalDiscountHandler);
    }

    @IsTest
    static void testForType_returnsOneTimeHandler() {
        DiscountTypeHandler handler = DiscountTypeHandler.forType('One-Time');
        Assert.isTrue(handler instanceof OneTimeDiscountHandler);
    }

    @IsTest
    static void testForType_unknownType_returnsOneTimeHandler() {
        DiscountTypeHandler handler = DiscountTypeHandler.forType('Unknown');
        Assert.isTrue(handler instanceof OneTimeDiscountHandler);
    }

    @IsTest
    static void testIsApplicable_targetAll_nullProducts_returnsTrue() {
        Discount__c d = makeDiscount('One-Time');
        // null Target_Application__c defaults to All Products

        DiscountTypeHandler handler = new OneTimeDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, Date.today(), new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isTrue(result);
    }

    @IsTest
    static void testIsApplicable_targetProducts_noLinkedProducts_returnsFalse() {
        Discount__c d = makeDiscount('One-Time');
        d.Target_Application__c = 'Specific Products';

        Product2 p = new Product2(Name = 'P1', IsActive = true);
        insert p;

        DiscountTypeHandler handler = new OneTimeDiscountHandler();
        Boolean result = handler.isApplicable(
            d, 100, Date.today(),
            new Set<Id>{ p.Id },
            new Map<Id, Decimal>{ p.Id => 1 },
            new Map<Id, String>(),
            null // no linked products
        );

        Assert.isFalse(result);
    }

    @IsTest
    static void testIsApplicable_targetProducts_productInOrderAndLinked_returnsTrue() {
        Discount__c d = makeDiscount('One-Time');
        d.Target_Application__c = 'Specific Products';

        Product2 p = new Product2(Name = 'P1', IsActive = true);
        insert p;

        DiscountTypeHandler handler = new OneTimeDiscountHandler();
        Set<Id> productIds = new Set<Id>{ p.Id };
        Boolean result = handler.isApplicable(
            d, 100, Date.today(),
            productIds,
            new Map<Id, Decimal>{ p.Id => 1 },
            new Map<Id, String>(),
            productIds // product is linked to discount
        );

        Assert.isTrue(result);
    }

    @IsTest
    static void testIsApplicable_targetProducts_linkedButNotInOrder_returnsFalse() {
        Discount__c d = makeDiscount('One-Time');
        d.Target_Application__c = 'Specific Products';

        Product2 p1 = new Product2(Name = 'P1', IsActive = true);
        Product2 p2 = new Product2(Name = 'P2', IsActive = true);
        insert new List<Product2>{ p1, p2 };

        DiscountTypeHandler handler = new OneTimeDiscountHandler();
        // p1 in order, p2 linked to discount but not in order
        Boolean result = handler.isApplicable(
            d, 100, Date.today(),
            new Set<Id>{ p1.Id },
            new Map<Id, Decimal>{ p1.Id => 1 },
            new Map<Id, String>(),
            new Set<Id>{ p2.Id }
        );

        Assert.isFalse(result);
    }

    @IsTest
    static void testIsApplicable_targetFamilies_nullFamilies_returnsFalse() {
        Discount__c d = makeDiscount('One-Time');
        d.Target_Application__c = 'Specific Families';
        d.Target_Families__c = null;

        Product2 p = new Product2(Name = 'P1', IsActive = true, Family = 'Electronics');
        insert p;

        DiscountTypeHandler handler = new OneTimeDiscountHandler();
        Boolean result = handler.isApplicable(
            d, 100, Date.today(),
            new Set<Id>{ p.Id },
            new Map<Id, Decimal>{ p.Id => 1 },
            new Map<Id, String>{ p.Id => 'Electronics' },
            null
        );

        Assert.isFalse(result);
    }

    @IsTest
    static void testIsApplicable_targetFamilies_noMatchingFamily_returnsFalse() {
        Discount__c d = makeDiscount('One-Time');
        d.Target_Application__c = 'Specific Families';
        d.Target_Families__c = 'Electronics';

        Product2 p = new Product2(Name = 'P1', IsActive = true, Family = 'Software');
        insert p;

        DiscountTypeHandler handler = new OneTimeDiscountHandler();
        Boolean result = handler.isApplicable(
            d, 100, Date.today(),
            new Set<Id>{ p.Id },
            new Map<Id, Decimal>{ p.Id => 1 },
            new Map<Id, String>{ p.Id => 'Software' },
            null
        );

        Assert.isFalse(result);
    }

    @IsTest
    static void testIsApplicable_targetFamilies_matchingFamily_returnsTrue() {
        Discount__c d = makeDiscount('One-Time');
        d.Target_Application__c = 'Specific Families';
        d.Target_Families__c = 'Electronics';

        Product2 p = new Product2(Name = 'P1', IsActive = true, Family = 'Electronics');
        insert p;

        DiscountTypeHandler handler = new OneTimeDiscountHandler();
        Boolean result = handler.isApplicable(
            d, 100, Date.today(),
            new Set<Id>{ p.Id },
            new Map<Id, Decimal>{ p.Id => 1 },
            new Map<Id, String>{ p.Id => 'Electronics' },
            null
        );

        Assert.isTrue(result);
    }

    @IsTest
    static void testIsApplicable_minimumQuantity_notMet_returnsFalse() {
        Discount__c d = makeDiscount('One-Time');
        d.Minimum_Quantity__c = 5;

        Product2 p = new Product2(Name = 'P1', IsActive = true);
        insert p;

        DiscountTypeHandler handler = new OneTimeDiscountHandler();
        Boolean result = handler.isApplicable(
            d, 100, Date.today(),
            new Set<Id>{ p.Id },
            new Map<Id, Decimal>{ p.Id => 2 }, // quantity 2 < minimum 5
            new Map<Id, String>(),
            null
        );

        Assert.isFalse(result);
    }

    @IsTest
    static void testIsApplicable_minimumQuantity_met_returnsTrue() {
        Discount__c d = makeDiscount('One-Time');
        d.Minimum_Quantity__c = 5;

        Product2 p = new Product2(Name = 'P1', IsActive = true);
        insert p;

        DiscountTypeHandler handler = new OneTimeDiscountHandler();
        Boolean result = handler.isApplicable(
            d, 100, Date.today(),
            new Set<Id>{ p.Id },
            new Map<Id, Decimal>{ p.Id => 10 }, // quantity 10 >= minimum 5
            new Map<Id, String>(),
            null
        );

        Assert.isTrue(result);
    }
}
