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
        helper.applyFilter(component, helper.FILTER.ALL);
    },

    handleFilterValid: function(component, event, helper) {
        helper.applyFilter(component, helper.FILTER.VALID);
    },

    handleFilterInvalid: function(component, event, helper) {
        helper.applyFilter(component, helper.FILTER.INVALID);
    },

    handleResultsPreviousPage: function(component, event, helper) {
        helper.changePage(component, helper.PAGINATION.RESULTS, -1);
    },

    handleResultsNextPage: function(component, event, helper) {
        helper.changePage(component, helper.PAGINATION.RESULTS, 1);
    },

    handlePreviousPage: function(component, event, helper) {
        helper.changePage(component, helper.PAGINATION.ROWS, -1);
    },

    handleNextPage: function(component, event, helper) {
        helper.changePage(component, helper.PAGINATION.ROWS, 1);
    },

    handleReset: function(component, resetEvent, helper) {
        component.set('v.parsedRows', []);
        component.set('v.filteredRows', []);
        component.set('v.pagedRows', []);
        component.set('v.importResults', []);
        component.set('v.isParsed', false);
        component.set('v.showResults', false);
        component.set('v.validCount', 0);
        component.set('v.errorCount', 0);
        component.set('v.filter', helper.FILTER.ALL);
        component.set('v.currentPage', 1);
        component.set('v.totalPages', 0);
        component.set('v.isFirstPage', true);
        component.set('v.isLastPage', true);
        component.set('v.pagedResults', []);
        component.set('v.resultsCurrentPage', 1);
        component.set('v.resultsTotalPages', 0);
        component.set('v.resultsIsFirstPage', true);
        component.set('v.resultsIsLastPage', true);
    }
})
