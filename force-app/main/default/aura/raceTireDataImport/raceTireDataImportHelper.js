({
    VALID_COMPOUNDS: ['Soft', 'Medium', 'Hard'],

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

    parseCSV: function(component, csvText) {
        var lines = csvText.trim().split('\n');
        if (lines.length < 2) {
            return;
        }

        var headers = lines[0].split(',').map(function(header) { return header.trim(); });
        var rows = [];
        var validCount = 0;
        var errorCount = 0;

        for (var rowIndex = 1; rowIndex < lines.length; rowIndex++) {
            if (!lines[rowIndex].trim()) {
                continue;
            }
            var values = lines[rowIndex].split(',').map(function(value) { return value.trim(); });

            var row = {
                rowNumber: rowIndex,
                trackName: this.getVal(headers, values, 'Track Name'),
                raceCountry: this.getVal(headers, values, 'Race Country'),
                raceName: this.getVal(headers, values, 'Race Name'),
                driver: this.getVal(headers, values, 'Driver'),
                team: this.getVal(headers, values, 'Team'),
                tireCompound: this.getVal(headers, values, 'Tire Compound'),
                laps: this.getVal(headers, values, 'Laps'),
                wearPercent: this.getVal(headers, values, 'Wear Percent')
            };

            var error = this.validate(row);
            row.isValid = !error;
            row.error = error || '';
            row.rowClass = error ? 'row-error' : 'row-success';

            if (error) {
                errorCount++;
            } else {
                validCount++;
            }

            rows.push(row);
        }

        component.set('v.parsedRows', rows);
        component.set('v.validCount', validCount);
        component.set('v.errorCount', errorCount);
        component.set('v.isParsed', true);
    },

    getVal: function(headers, values, key) {
        var headerIndex = headers.indexOf(key);
        return headerIndex >= 0 ? (values[headerIndex] || '') : '';
    },

    validate: function(row) {
        if (!row.trackName) {
            return this.label('ERR_TRACK_NAME_REQUIRED');
        }
        if (!row.raceName) {
            return this.label('ERR_RACE_NAME_REQUIRED');
        }
        if (!row.driver) {
            return this.label('ERR_DRIVER_REQUIRED');
        }
        if (!row.tireCompound) {
            return this.label('ERR_COMPOUND_REQUIRED');
        }
        if (this.VALID_COMPOUNDS.indexOf(row.tireCompound) === -1) {
            return this.label('ERR_COMPOUND_INVALID');
        }
        if (!row.laps) {
            return this.label('ERR_LAPS_REQUIRED');
        }
        var laps = parseInt(row.laps, 10);
        if (isNaN(laps)) {
            return this.label('ERR_LAPS_NOT_NUMBER');
        }
        if (laps <= 0) {
            return this.label('ERR_LAPS_INVALID');
        }
        if (row.wearPercent === '') {
            return this.label('ERR_WEAR_REQUIRED');
        }
        var wear = parseFloat(row.wearPercent);
        if (isNaN(wear)) {
            return this.label('ERR_WEAR_INVALID');
        }
        if (wear < 0 || wear > 100) {
            return this.label('ERR_WEAR_RANGE');
        }
        return null;
    },

    importRecords: function(component) {
        component.set('v.isLoading', true);

        var allRows = component.get('v.parsedRows');
        var validRows = allRows.filter(function(row) { return row.isValid; });
        var invalidRows = allRows.filter(function(row) { return !row.isValid; });

        var action = component.get('c.importRecords');
        action.setParams({ rowsJson: JSON.stringify(validRows) });

        var helper = this;
        action.setCallback(this, function(response) {
            component.set('v.isLoading', false);
            if (response.getState() === 'SUCCESS') {
                var savedLabel = helper.label('SAVED_PREFIX');

                var importedResults = response.getReturnValue().map(function(importResult) {
                    var isSuccess = importResult.status === 'success';
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

        $A.enqueueAction(action);
    }
})
