% nfblab_version() - get current nfblab commit
%
% Usage:
%    commit = nfblab_version

function res = nfblab_version

if ~isdeployed
    disp('Looking up software version (commit hash)')
    [status,res] = system('git rev-parse HEAD');
    nfblabFolder = fileparts(which('nfblab_version.m'));
    fileName = fullfile( nfblabFolder, 'nfblab_commit.txt');
else
    status = 1;
    res = '';
    fileName = fullfile( ctfroot, 'nfblab_commit.txt');
end

if status ~= 0
    try
        disp('Could not look up software version; Loading software version from file.')
        res = load('-ascii', fileName);
        res = char(res);
    catch
        fprintf(2, 'Warning: commit file not found, cannot log software version')
    end
else
    try
        disp('Saving software version')
        res = deblank(res);
        save('-ascii', fileName, 'res')
    catch
        fprintf(2, 'Warning: could not save software version')
    end
end
