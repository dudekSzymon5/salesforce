({
    VALID_COMPOUNDS: ['Soft', 'Medium', 'Hard'],

    STATUS: {
        APEX_SUCCESS: 'SUCCESS',
        RECORD_SUCCESS: 'success',
        RECORD_ERROR: 'error'
    },

    LABELS: {
        ERR_TRACK_NAME_REQUIRED: '$Label.c.RaceTireImport_ErrTrackNameRequired',
        ERR_RACE_NAME_REQUIRED: '$Label.c.RaceTireImport_ErrRaceNameRequired',
        ERR_DRIVER_REQUIRED: '$Label.c.RaceTireImport_ErrDriverRequired',
        ERR_COMPOUND_REQUIRED: '$Label.c.RaceTireImport_ErrCompoundRequired',
        ERR_COMPOUND_INVALID: '$Label.c.RaceTireImport_ErrCompoundInvalid',
        ERR_LAPS_REQUIRED: '$Label.c.RaceTireImport_ErrLapsRequired',
        ERR_LAPS_NOT_NUMBER: '$Label.c.RaceTireImport_ErrLapsNotNumber',
        ERR_LAPS_INVALID: '$Label.c.RaceTireImport_ErrLapsInvalid',
        ERR_WEAR_REQUIRED: '$Label.c.RaceTireImport_ErrWearRequired',
        ERR_WEAR_INVALID: '$Label.c.RaceTireImport_ErrWearInvalid',
        ERR_WEAR_RANGE: '$Label.c.RaceTireImport_ErrWearRange',
        ERR_IMPORT_FAILED: '$Label.c.RaceTireImport_ErrImportFailed',
        SAVED_PREFIX: '$Label.c.RaceTireImport_SavedPrefix'
    },

    label: function(key) {
        return $A.get(this.LABELS[key]);
    },

    detectSeparator: function(headerLine) {
        if (headerLine.indexOf(';') !== -1) {
            return ';';
        }
        if (headerLine.indexOf('\t') !== -1) {
            return '\t';
        }
        return ',';
    },

    parseCSV: function(component, csvText) {
        var lines = csvText.trim().split('\n');
        if (lines.length < 2) {
            return;
        }

        var separator = this.detectSeparator(lines[0]);
        var headers = lines[0].split(separator).map(function(header) {
            return header.trim();
        });
        var rows = [];
        var validCount = 0;
        var errorCount = 0;

        for (var rowIndex = 1; rowIndex < lines.length; rowIndex++) {
            if (!lines[rowIndex].trim()) { // Jeśli linia po usunięciu white spaces jest pusta to continue;
                continue;
            }
            var values = lines[rowIndex].split(separator).map(function(value) {
                return value.trim(); 
            });

            var row = {
                rowNumber: rowIndex,
                trackName: this.getColumnValue(headers, values, 'Track Name'),
                raceCountry: this.getColumnValue(headers, values, 'Race Country'),
                raceName: this.getColumnValue(headers, values, 'Race Name'),
                driver: this.getColumnValue(headers, values, 'Driver'),
                team: this.getColumnValue(headers, values, 'Team'),
                tireCompound: this.getColumnValue(headers, values, 'Tire Compound'),
                laps: this.getColumnValue(headers, values, 'Laps'),
                wearPercent: this.getColumnValue(headers, values, 'Wear Percent')
            };

            var errors = this.validate(row);
            row.isValid = errors.length === 0;
            row.error = errors.join(' | ');
            row.rowClass = errors.length > 0 ? 'row-error' : 'row-success';

            if (errors.length > 0) {
                errorCount++;
            } else {
                validCount++;
            }

            rows.push(row);
        }

        component.set('v.parsedRows', rows);
        component.set('v.validCount', validCount);
        component.set('v.errorCount', errorCount);
        component.set('v.filter', 'all');
        component.set('v.filteredRows', rows);
        component.set('v.isParsed', true);
    },

    getColumnValue: function(headers, values, key) {
        var headerIndex = headers.indexOf(key);
        return headerIndex >= 0 ? (values[headerIndex] || '') : '';
    },

    validate: function(row) {
        var errors = [];

        if (!row.trackName) errors.push(this.label('ERR_TRACK_NAME_REQUIRED'));
        if (!row.raceName) errors.push(this.label('ERR_RACE_NAME_REQUIRED'));
        if (!row.driver) errors.push(this.label('ERR_DRIVER_REQUIRED'));

        if (!row.tireCompound) {
            errors.push(this.label('ERR_COMPOUND_REQUIRED'));
        } else if (this.VALID_COMPOUNDS.indexOf(row.tireCompound) === -1) {
            errors.push(this.label('ERR_COMPOUND_INVALID'));
        }

        if (!row.laps) {
            errors.push(this.label('ERR_LAPS_REQUIRED'));
        } else {
            var laps = parseInt(row.laps, 10);
            if (isNaN(laps)) {
                errors.push(this.label('ERR_LAPS_NOT_NUMBER'));
            } else if (laps <= 0) {
                errors.push(this.label('ERR_LAPS_INVALID'));
            }
        }

        if (row.wearPercent === '') {
            errors.push(this.label('ERR_WEAR_REQUIRED'));
        } else {
            var wear = parseFloat(row.wearPercent);
            if (isNaN(wear)) {
                errors.push(this.label('ERR_WEAR_INVALID'));
            } else if (wear < 0 || wear > 100) {
                errors.push(this.label('ERR_WEAR_RANGE'));
            }
        }

        return errors;
    },

    applyFilter: function(component, filter) {
        var allRows = component.get('v.parsedRows');
        var filtered;
        if (filter === 'valid') {
            filtered = allRows.filter(function(row) { return row.isValid; });
        } else if (filter === 'invalid') {
            filtered = allRows.filter(function(row) { return !row.isValid; });
        } else {
            filtered = allRows;
        }
        component.set('v.filter', filter);
        component.set('v.filteredRows', filtered);
    },

    downloadCSV: function(rows, filename) {
        var quote = String.fromCharCode(34);
        var wrapInQuotes = function(text) { 
            return quote + (text || '').split(quote).join(quote + quote) + quote; 
        };

        var headers = ['#', 'Driver', 'Team', 'Track Name', 'Race Name', 'Message'];
        var lines = [headers.join(',')];
        rows.forEach(function(row) {
            lines.push([
                row.rowNumber,
                wrapInQuotes(row.driver),
                wrapInQuotes(row.team),
                wrapInQuotes(row.trackName),
                wrapInQuotes(row.raceName),
                wrapInQuotes(row.message)
            ].join(','));
        });
        var csv = lines.join('\n');
        var link = document.createElement('a');
        link.setAttribute('href', 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv));
        link.setAttribute('download', filename);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    },

    importRecords: function(component) {
        component.set('v.isLoading', true);

        var allRows = component.get('v.parsedRows');

        var validRows = allRows.filter(function(row) {
            return row.isValid; 
        });

        var invalidRows = allRows.filter(function(row) { 
            return !row.isValid; 
        });

        var action = component.get('c.importRecords');
        action.setParams ({ 
            rowsJson: JSON.stringify(validRows) 
        });

        var helper = this;
        action.setCallback(this, function(response) {
            component.set('v.isLoading', false);
            if (response.getState() === helper.STATUS.APEX_SUCCESS) {
                var savedLabel = helper.label('SAVED_PREFIX');

                var importedResults = response.getReturnValue().map(function(importResult) {
                    var isSuccess = importResult.status === helper.STATUS.RECORD_SUCCESS;
                    return {
                        rowNumber: importResult.rowNumber,
                        driver: importResult.driver,
                        team: importResult.team,
                        trackName: importResult.trackName,
                        raceName: importResult.raceName,
                        isSuccess: isSuccess,
                        message: isSuccess
                            ? savedLabel + ' (ID: ' + importResult.recordId + ')'
                            : importResult.errorMessage,
                        rowClass: isSuccess ? 'row-success' : 'row-error'
                    };
                });

                var rejectedResults = invalidRows.map(function(row) {
                    return {
                        rowNumber: row.rowNumber,
                        driver: row.driver,
                        team: row.team,
                        trackName: row.trackName,
                        raceName: row.raceName,
                        isSuccess: false,
                        message: row.error,
                        rowClass: 'row-error'
                    };
                });

                var allResults = importedResults.concat(rejectedResults);
                allResults.sort(function(firstResult, secondResult) {
                    return firstResult.rowNumber - secondResult.rowNumber;
                });

                component.set('v.importResults', allResults);
                component.set('v.isParsed', false);
                component.set('v.showResults', true);
            } else {
                alert(helper.label('ERR_IMPORT_FAILED') + ': ' + response.getError()[0].message);
            }
        });

        $A.enqueueAction(action); // Wysyłanie danych do APEX
    }
})
