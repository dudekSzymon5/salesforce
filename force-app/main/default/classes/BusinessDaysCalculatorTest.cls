@IsTest
private class BusinessDaysCalculatorTest {
    
    @IsTest
    static void testCalculateBusinessDeadline() {
        BusinessDaysCalculator.FlowInput input = new BusinessDaysCalculator.FlowInput();
        input.startDate = Date.newInstance(2025, 1, 6);
        
        List<BusinessDaysCalculator.FlowInput> inputs = new List<BusinessDaysCalculator.FlowInput>{ input };
        
        Test.startTest();
        List<BusinessDaysCalculator.FlowOutput> results = BusinessDaysCalculator.calculate(inputs);
        Test.stopTest();
        
        Assert.isNotNull(results);
        Assert.areEqual(1, results.size());
        Assert.areEqual(Date.newInstance(2025, 1, 13), results[0].deadlineDate);
    }
    
    @IsTest
    static void testCalculateMultipleInputs() {
        BusinessDaysCalculator.FlowInput input1 = new BusinessDaysCalculator.FlowInput();
        input1.startDate = Date.newInstance(2025, 1, 6);
        
        BusinessDaysCalculator.FlowInput input2 = new BusinessDaysCalculator.FlowInput();
        input2.startDate = Date.newInstance(2025, 1, 13);
        
        List<BusinessDaysCalculator.FlowInput> inputs = new List<BusinessDaysCalculator.FlowInput>{ input1, input2 };
        
        Test.startTest();
        List<BusinessDaysCalculator.FlowOutput> results = BusinessDaysCalculator.calculate(inputs);
        Test.stopTest();
        
        Assert.areEqual(2, results.size());
        Assert.isNotNull(results[0].deadlineDate);
        Assert.isNotNull(results[1].deadlineDate);
    }
}