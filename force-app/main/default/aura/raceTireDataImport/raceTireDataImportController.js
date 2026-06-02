({
    handleFileChange: function(component, fileChangeEvent, helper) {
        var file = fileChangeEvent.getSource().get('v.files')[0];
        if (!file) {
            return;
        }
        var reader = new FileReader();
        reader.onload = function(loadEvent) {
            helper.parseCSV(component, loadEvent.target.result);
        };
        reader.readAsText(file);
    },

    handleImport: function(component, importEvent, helper) {
        helper.importRecords(component);
    },

    handleGoToRecords: function(component, goToRecordsEvent, helper) {
        var navigationEvent = $A.get('e.force:navigateToObjectHome');
        navigationEvent.setParams({ scope: 'Race_Tire_Data__c' });
        navigationEvent.fire();
    },

    handleDownloadSuccess: function(component, event, helper) {
        var results = component.get('v.importResults').filter(function(result) {
            return result.isSuccess;
        });
        helper.downloadCSV(results, $A.get('$Label.c.RaceTireImport_FileSuccess'));
    },

    handleDownloadErrors: function(component, event, helper) {
        var results = component.get('v.importResults').filter(function(result) {
            return !result.isSuccess;
        });
        helper.downloadCSV(results, $A.get('$Label.c.RaceTireImport_FileErrors'));
    },

    handleFilterAll: function(component, event, helper) {
        helper.applyFilter(component, 'all');
    },

    handleFilterValid: function(component, event, helper) {
        helper.applyFilter(component, 'valid');
    },

    handleFilterInvalid: function(component, event, helper) {
        helper.applyFilter(component, 'invalid');
    },

    handleReset: function(component, resetEvent, helper) {
        component.set('v.parsedRows', []);
        component.set('v.filteredRows', []);
        component.set('v.importResults', []);
        component.set('v.isParsed', false);
        component.set('v.showResults', false);
        component.set('v.validCount', 0);
        component.set('v.errorCount', 0);
        component.set('v.filter', 'all');
    }
})
