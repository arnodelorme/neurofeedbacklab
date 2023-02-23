% Legacy function no longer used to import loreta information

function [loretadata, freqs4 ] = nfblab_importloreta( filename )

% tmp = loadtxt(filename, 'delim', ',', 'verbose', 'off', 'convert', 'off');
% freqs4 = tmp(1,7:end);
% freqs4 = cellfun(@(x)str2double(x(1:end-3)), freqs4);
% tmp = tmp(2:end,7:end);
% loretadata = cellfun(@str2double, tmp);

warning off;
tmp = readtable(filename);
warning on;
headers = fieldnames(tmp);
headers = strrep(headers, '_', '.');
freqs4 = cellfun(@(x)str2double(x(2:end-3)), headers(7:end-3))';
loretadata = table2array(tmp(:,7:end));
