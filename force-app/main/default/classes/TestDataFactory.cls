@IsTest
public class TestDataFactory {

    public class ProductBuilder {
        private String name = 'Test Product';
        private String code = 'PROD-001';
        private String family = 'Software';
        private Boolean isActive = true;
        private Boolean isExternal = false;
        private Boolean isDeleted = false;
        private String externalId;
        private String externalOrgId;
        private String description;
        private String language;

        public ProductBuilder withName(String productName) { name = productName; return this; }
        public ProductBuilder withCode(String productCode) { code = productCode; return this; }
        public ProductBuilder withFamily(String productFamily) { family = productFamily; return this; }
        public ProductBuilder withDescription(String productDescription) { description = productDescription; return this; }
        public ProductBuilder withLanguage(String productLanguage) { language = productLanguage; return this; }
        public ProductBuilder inactive() { isActive = false; return this; }

        public ProductBuilder external() {
            isExternal = true;
            return this;
        }

        public ProductBuilder external(String newExternalId, String orgId) {
            isExternal = true;
            externalId = newExternalId;
            externalOrgId = orgId;
            return this;
        }

        public ProductBuilder deleted() {
            isDeleted = true;
            isExternal = true;
            return this;
        }

        public Product2 build() {
            return new Product2(
                Name = name,
                ProductCode = code,
                Family = family,
                IsActive = isActive,
                Is_External__c = isExternal,
                Is_Deleted__c = isDeleted,
                External_Product_Id__c = externalId,
                External_Org_Id__c = externalOrgId,
                Description = description,
                Language__c = language
            );
        }

        public Product2 create() {
            Product2 product = build();
            insert product;
            return product;
        }
    }

    public class DiscountBuilder {
        private String name = 'Test Discount';
        private String type = Utils.DISCOUNT.TYPE.ONE_TIME;
        private String form = Utils.DISCOUNT.FORM.PERCENTAGE;
        private Decimal value = 10;
        private Boolean active = true;
        private String conditionType;
        private String pattern;
        private Decimal minOrder;
        private Decimal minQty;
        private String target;
        private String families;
        private Date startDate;
        private Date endDate;

        public DiscountBuilder withName(String discountName) { name = discountName; return this; }
        public DiscountBuilder withValue(Decimal discountValue) { value = discountValue; return this; }
        public DiscountBuilder asAmount() { form = Utils.DISCOUNT.FORM.AMOUNT; return this; }
        public DiscountBuilder inactive() { active = false; return this; }
        public DiscountBuilder oneTime() { type = Utils.DISCOUNT.TYPE.ONE_TIME; return this; }
        public DiscountBuilder withMinOrder(Decimal minimumAmount) { minOrder = minimumAmount; return this; }
        public DiscountBuilder withMinQuantity(Decimal minimumQuantity) { minQty = minimumQuantity; return this; }
        public DiscountBuilder forProducts() { target = Utils.DISCOUNT.TARGET.PRODUCTS; return this; }
        public DiscountBuilder validFrom(Date startDate) { this.startDate = startDate; return this; }
        public DiscountBuilder validUntil(Date endDate) { this.endDate = endDate; return this; }

        public DiscountBuilder recurring(String recurrencePattern) {
            type = Utils.DISCOUNT.TYPE.RECURRING;
            pattern = recurrencePattern;
            return this;
        }

        public DiscountBuilder conditional(String conditionType) {
            type = Utils.DISCOUNT.TYPE.CONDITIONAL;
            this.conditionType = conditionType;
            return this;
        }

        public DiscountBuilder forFamilies(String familyList) {
            target = Utils.DISCOUNT.TARGET.FAMILIES;
            families = familyList;
            return this;
        }

        public Discount__c build() {
            return new Discount__c(
                Name = name,
                Type__c = type,
                Discount_Form__c = form,
                Value__c = value,
                Is_Active__c = active,
                Condition_Type__c = conditionType,
                Recurrence_Pattern__c = pattern,
                Minimum_Order_Amount__c = minOrder,
                Minimum_Quantity__c = minQty,
                Target_Application__c = target,
                Target_Families__c = families,
                Start_Date__c = startDate,
                End_Date__c = endDate
            );
        }

        public Discount__c create() {
            Discount__c discount = build();
            insert discount;
            return discount;
        }
    }

    public class QueueBuilder {
        private Id productId;
        private String operation = Utils.PRODUCT_SYNC.OPERATION.INSERT_OP;
        private String payload = '{"test":"payload"}';
        private String status = Utils.PRODUCT_SYNC.STATUS.FAILED;
        private Integer attempts = 1;

        public QueueBuilder forProduct(Id productId) { this.productId = productId; return this; }
        public QueueBuilder withAttempts(Integer attemptCount) { attempts = attemptCount; return this; }
        public QueueBuilder withPayload(String queuePayload) { payload = queuePayload; return this; }

        public QueueBuilder asDelete(String externalId) {
            operation = Utils.PRODUCT_SYNC.OPERATION.DELETE_OP;
            productId = null;
            payload = externalId;
            return this;
        }

        public Product_Sync_Queue__c build() {
            return new Product_Sync_Queue__c(
                Product__c = productId,
                Operation__c = operation,
                Payload__c = payload,
                Status__c = status,
                Attempt_Count__c = attempts,
                Last_Attempt__c = DateTime.now().addHours(-1),
                Target_Org__c = Utils.PRODUCT_SYNC.API.NAMED_CREDENTIAL
            );
        }

        public Product_Sync_Queue__c create() {
            Product_Sync_Queue__c queueRecord = build();
            insert queueRecord;
            return queueRecord;
        }
    }

    public class OrderBuilder {
        private Id accountId;
        private Id contractId;
        private Id pricebookId;
        private String status = 'Draft';

        public OrderBuilder forAccount(Id accountId) { this.accountId = accountId; return this; }
        public OrderBuilder withContract(Id contractId) { this.contractId = contractId; return this; }
        public OrderBuilder withPricebook(Id pricebookId) { this.pricebookId = pricebookId; return this; }

        public Order build() {
            return new Order(
                AccountId = accountId,
                ContractId = contractId,
                Status = status,
                EffectiveDate = Date.today(),
                Pricebook2Id = pricebookId != null ? pricebookId : Test.getStandardPricebookId()
            );
        }

        public Order create() {
            Order order = build();
            insert order;
            return order;
        }
    }

    public class HttpMock implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        public HttpMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setBody(body);
            return response;
        }
    }

    public static ProductBuilder aProduct() { return new ProductBuilder(); }
    public static DiscountBuilder aDiscount() { return new DiscountBuilder(); }
    public static QueueBuilder aQueueRecord() { return new QueueBuilder(); }
    public static OrderBuilder anOrder() { return new OrderBuilder(); }

    public static HttpMock httpSuccess() { return new HttpMock(200, '{"status":"success"}'); }
    public static HttpMock httpSuccess(String body) { return new HttpMock(200, body); }
    public static HttpMock httpError() { return new HttpMock(500, '{"status":"error","message":"Internal Server Error"}'); }
    public static HttpMock httpError(Integer statusCode, String body) { return new HttpMock(statusCode, body); }

    public static Account createAccount() {
        Account account = new Account(Name = 'Test Account');
        insert account;
        return account;
    }

    public static Opportunity createOpportunity(Id accountId) {
        Opportunity opportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = accountId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert opportunity;
        return opportunity;
    }

    public static Contract createContract(Id accountId) {
        Contract contract = new Contract(
            AccountId = accountId,
            StartDate = Date.today(),
            ContractTerm = 12,
            Status = 'Draft'
        );
        insert contract;
        contract.Status = 'Activated';
        update contract;
        return contract;
    }

    public static PricebookEntry addToPricebook(Id productId, Decimal price) {
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = productId,
            UnitPrice = price,
            IsActive = true
        );
        insert pricebookEntry;
        return pricebookEntry;
    }

    public static void setupRestPost(String uri, String jsonBody) {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestURI = uri;
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);
    }

    public static void setupRestDelete(String uri) {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestURI = uri;
        RestContext.request.httpMethod = 'DELETE';
    }

    public static String buildProductPayload(String externalProductId, String externalOrgId, String productName) {
        return JSON.serialize(new Map<String, Object>{
            'externalProductId' => externalProductId,
            'externalOrgId' => externalOrgId,
            'name' => productName,
            'description' => 'Test Description',
            'productCode' => 'TEST-001',
            'family' => 'Software',
            'language' => 'English'
        });
    }
}