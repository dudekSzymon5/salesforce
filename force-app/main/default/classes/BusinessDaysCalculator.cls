public class BusinessDaysCalculator {
    
    public class FlowInput {
        @InvocableVariable(required=true)
        public Date startDate;
    }
    
    public class FlowOutput {
        @InvocableVariable
        public Date deadlineDate;
    }
    
    @InvocableMethod(label='Calculate Business Deadline')
    public static List<FlowOutput> calculate(List<FlowInput> inputs) {
        List<FlowOutput> results = new List<FlowOutput>();
        for (FlowInput input : inputs) {
            Date current = input.startDate;
            Integer added = 0;
            while (added < 5) {
                current = current.addDays(1);
                Integer dow = Math.mod(Date.newInstance(1900,1,7)
                    .daysBetween(current), 7);
                if (dow != 0 && dow != 6) added++;
            }
            FlowOutput out = new FlowOutput();
            out.deadlineDate = current;
            results.add(out);
        }
        return results;
    }
}