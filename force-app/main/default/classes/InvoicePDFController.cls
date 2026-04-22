public class InvoicePDFController {
    public Invoice__c invoice { get; set; }
    public List<OrderItem> orderItems { get; set; }
    public Decimal subtotal { get; set; }
    public Decimal vatAmount { get; set; }
    public Decimal total { get; set; }

    public InvoicePDFController(ApexPages.StandardController sc) {
        invoice = [
            SELECT Id, Name, Status__c,
                   Order__r.OrderNumber,
                   Order__r.TotalAmount,
                   Order__r.EffectiveDate,
                   Order__r.Account.Name,
                   Order__r.Account.BillingStreet,
                   Order__r.Account.BillingCity,
                   Order__r.Account.BillingCountry,
                   Order__r.Account.Phone
            FROM Invoice__c
            WHERE Id = :sc.getId()
        ];

        orderItems = [
            SELECT Product2.Name, Quantity, UnitPrice, TotalPrice
            FROM OrderItem
            WHERE OrderId = :invoice.Order__c
        ];

        subtotal = invoice.Order__r.TotalAmount != null ? invoice.Order__r.TotalAmount : 0;
        vatAmount = subtotal * 0.23;
        total = subtotal + vatAmount;
    }
}