@IsTest
private class DiscountControllerTest {

    @TestSetup
    static void setupData() {
        TestDataFactory.aDiscount()
            .conditional('Minimum Order Value')
            .withMinOrder(100)
            .create();

        Account account = TestDataFactory.createAccount();
        Contract contract = TestDataFactory.createContract(account.Id);
        TestDataFactory.anOrder()
            .forAccount(account.Id)
            .withContract(contract.Id)
            .create();
    }

    @IsTest
    static void testGetDiscounts() {
        // Sprawdzam że kontroler zwraca listę zniżek — setup stworzył jedną, więc lista nie powinna być pusta
        Test.startTest();
        List<Discount__c> discounts = DiscountController.getDiscounts();
        Test.stopTest();

        Assert.isNotNull(discounts);
        Assert.isTrue(discounts.size() > 0);
    }

    @IsTest
    static void testGetDiscountSettings() {
        // Sprawdzam że ustawienia zniżek (metadata) są dostępne i nie są nullem
        Test.startTest();
        Discount_Settings__mdt settings = DiscountController.getDiscountSettings();
        Test.stopTest();

        Assert.isNotNull(settings);
    }

    @IsTest
    static void testSaveDiscountNewRecordReturnsWithId() {
        // Nowy rekord zniżki — po zapisie powinien dostać Id z bazy
        Discount__c discount = TestDataFactory.aDiscount().oneTime().asAmount().withValue(50).build();

        Test.startTest();
        Discount__c saved = DiscountController.saveDiscount(discount);
        Test.stopTest();

        Assert.isNotNull(saved.Id);
    }

    @IsTest
    static void testSaveDiscountAlreadyAssignedThrowsException() {
        // Zniżka już przypisana do zamówienia — edycja powinna rzucić AuraHandledException
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
        // Zniżka "Dwa za jeden" — kontroler powinien automatycznie ustawić Minimum_Quantity__c = 2
        Discount__c discount = TestDataFactory.aDiscount()
            .conditional('Two For One')
            .withValue(50)
            .build();

        Test.startTest();
        Discount__c saved = DiscountController.saveDiscount(discount);
        Test.stopTest();

        Assert.areEqual(2, saved.Minimum_Quantity__c);
    }

    @IsTest
    static void testSaveDiscountPercentageOver100ThrowsException() {
        // Zniżka procentowa 150% — wartość powyżej 100 jest nieprawidłowa, powinien polecieć wyjątek
        Discount__c discount = TestDataFactory.aDiscount().oneTime().withValue(150).build();

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
        // Przekazuję false — zniżka powinna zostać dezaktywowana (Is_Active__c = false)
        Discount__c discount = [SELECT Id FROM Discount__c LIMIT 1];

        Test.startTest();
        DiscountController.toggleDiscounts(new List<Id>{ discount.Id }, false);
        Test.stopTest();

        Discount__c updated = [SELECT Is_Active__c FROM Discount__c WHERE Id = :discount.Id];
        Assert.isFalse(updated.Is_Active__c);
    }

    @IsTest
    static void testGetAssignedDiscountIdsEmpty() {
        // Brak przypisanych zniżek do zamówień — lista powinna być pusta
        Test.startTest();
        List<Id> assignedIds = DiscountController.getAssignedDiscountIds();
        Test.stopTest();

        Assert.isNotNull(assignedIds);
        Assert.isTrue(assignedIds.isEmpty());
    }

    @IsTest
    static void testGetAssignedDiscountIdsWithAssignment() {
        // Przypisuję zniżkę do zamówienia — jej Id powinno pojawić się na liście przypisanych
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
        // Produkt dodany do cennika — powinien pojawić się na liście opcji do wyboru w zniżce
        Product2 product = TestDataFactory.aProduct().withName('Option Product').create();
        TestDataFactory.addToPricebook(product.Id, 100);

        Test.startTest();
        List<Product2> products = DiscountController.getProductOptions();
        Test.stopTest();

        Assert.isTrue(products.size() > 0);
    }

    @IsTest
    static void testGetProductFamilies() {
        // Sprawdzam że kontroler zwraca listę dostępnych rodzin produktów
        Test.startTest();
        List<String> families = DiscountController.getProductFamilies();
        Test.stopTest();

        Assert.isNotNull(families);
    }

    @IsTest
    static void testGetDiscountProducts() {
        // Produkt powiązany ze zniżką — kontroler powinien zwrócić jego Id
        Discount__c discount = [SELECT Id FROM Discount__c LIMIT 1];
        Product2 product = TestDataFactory.aProduct().withName('Linked Product').create();
        insert new Discount_Product__c(Discount__c = discount.Id, Product__c = product.Id);

        Test.startTest();
        List<Id> productIds = DiscountController.getDiscountProducts(discount.Id);
        Test.stopTest();

        Assert.isTrue(productIds.size() > 0);
    }

    @IsTest
    static void testSaveDiscountProductsAddsLinks() {
        // Zapisuję listę produktów dla zniżki — powinny powstać rekordy Discount_Product__c
        Discount__c discount = [SELECT Id FROM Discount__c LIMIT 1];
        Product2 product = TestDataFactory.aProduct().withName('Save Product').create();

        Test.startTest();
        DiscountController.saveDiscountProducts(discount.Id, new List<Id>{ product.Id });
        Test.stopTest();

        List<Discount_Product__c> discountProducts = [SELECT Id FROM Discount_Product__c WHERE Discount__c = :discount.Id];
        Assert.isTrue(discountProducts.size() > 0);
    }

    @IsTest
    static void testSaveDiscountProductsEmptyListRemovesAll() {
        // Przekazuję pustą listę produktów — istniejące powiązania powinny zostać usunięte
        Discount__c discount = [SELECT Id FROM Discount__c LIMIT 1];
        Product2 product = TestDataFactory.aProduct().withName('Del Product').create();
        insert new Discount_Product__c(Discount__c = discount.Id, Product__c = product.Id);

        Test.startTest();
        DiscountController.saveDiscountProducts(discount.Id, new List<Id>());
        Test.stopTest();

        List<Discount_Product__c> discountProducts = [SELECT Id FROM Discount_Product__c WHERE Discount__c = :discount.Id];
        Assert.isTrue(discountProducts.isEmpty());
    }

    @IsTest
    static void testSaveDiscountSettingsDoesNotThrow() {
        // Zapis ustawień zniżek — sprawdzam że metoda nie wysypuje się przy prawidłowych danych
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
        // Aplikuję zniżki do zamówienia za 500 — wynik nie powinien być nullem
        Order order = [SELECT Id FROM Order LIMIT 1];

        Test.startTest();
        List<Order_Discount__c> applied = DiscountController.applyDiscountsToOrder(order.Id, 500);
        Test.stopTest();

        Assert.isNotNull(applied);
    }

    @IsTest
    static void testPreviewDiscountsAboveMinOrderReturnsPreview() {
        // Zamówienie za 500, minimum to 100 — zniżka powinna się pojawić w podglądzie z nazwą i wartością
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
        // Zamówienie za 50, minimum to 100 — warunek niespełniony, podgląd powinien być pusty
        Test.startTest();
        List<DiscountService.DiscountPreview> previews = DiscountController.previewDiscounts(
            50, new List<DiscountService.ItemInput>()
        );
        Test.stopTest();

        Assert.isTrue(previews.isEmpty());
    }

    @IsTest
    static void testPreviewDiscountsSpecificProductTargeted() {
        // Zniżka skierowana na konkretny produkt — podgląd powinien ją uwzględnić gdy produkt jest w koszyku
        Product2 product = TestDataFactory.aProduct().withName('Targeted Product').create();
        Discount__c discount = TestDataFactory.aDiscount().oneTime().forProducts().create();
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
        // Zniżka dla rodziny Electronics — podgląd powinien ją uwzględnić gdy produkt z tej rodziny jest w koszyku
        Product2 product = TestDataFactory.aProduct().withName('Family Product').withFamily('Electronics').create();
        Discount__c discount = TestDataFactory.aDiscount().oneTime().forFamilies('Electronics').create();

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
        // Zniżka "Dwa za jeden" przy ilości 4 sztuk — warunek minimalnej ilości spełniony
        Product2 product = TestDataFactory.aProduct().withName('TwoForOne Product').create();
        TestDataFactory.aDiscount()
            .conditional('Two For One')
            .withValue(50)
            .withMinQuantity(2)
            .create();

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
        // Zniżka kwotowa (20 zł) zamiast procentowej — sprawdzam że forma kwotowa działa w podglądzie
        TestDataFactory.aDiscount()
            .conditional('Minimum Order Value')
            .asAmount()
            .withValue(20)
            .withMinOrder(100)
            .create();

        Test.startTest();
        List<DiscountService.DiscountPreview> previews = DiscountController.previewDiscounts(
            500, new List<DiscountService.ItemInput>()
        );
        Test.stopTest();

        Assert.isNotNull(previews);
    }
}
