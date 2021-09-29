function result = nfblab_zscore(result, zarray, agerange)

% indices
ageInds = [zarray.age] >= agerange(1) & [zarray.age] <= agerange(2); 

fields = fieldnames(result);
noNorm = true;
for iField = 1:length(fields)
    if isfield(zarray, fields{iField})
        tmpVals = [zarray.(fields{iField})];
        meanVal = mean(tmpVals(ageInds));
        stdVal  = std( tmpVals(ageInds));
        result.([ 'z' fields{iField} ]) = (result.(fields{iField})-meanVal)/stdVal;
        noNorm = false;
    end
end

if noNorm
    error('No field could be normalized, are you sure you want to normalize fields');
end