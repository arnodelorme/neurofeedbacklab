% import nfblab_process log from JSON file
% useful to extract information

function logData = nfblab_importlog(fileName)

fid = fopen(fileName, 'r');
if fid == -1
    error('File does not exist');
end

logData = [];
while ~feof(fid)
    rawLine = fgetl(fid);
    
    begBracket = find(rawLine == '{');
    endBracket = find(rawLine == '}');
    if length(begBracket) == 1 && ~isempty(begBracket) && ~isempty(endBracket) && begBracket+2 < endBracket
        jsonStr = jsondecode(rawLine(begBracket:endBracket));
        if isempty(logData)
            logData = jsonStr;
        else
            % copy field by field to avoid issue with inconsistent
            % structures
            fields = fieldnames(jsonStr);
            for iField = 1:length(fields)
                if iField == 1
                    logData(end+1).(fields{iField}) = jsonStr.(fields{iField});
                else
                    logData(end).(fields{iField}) = jsonStr.(fields{iField});
                end
            end
        end
    end
end

fclose(fid);