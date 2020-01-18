function result = nfblab_findstream(lib,lsltype,lslname)

if ~isempty(lsltype) && ~isempty(lslname)
    result = lsl_resolve_byprop(lib, 'type', lsltype, 'name', lslname);
elseif ~isempty(lsltype)
    result = lsl_resolve_byprop(lib, 'type', lsltype);
elseif ~isempty(lslname)
    result = lsl_resolve_byprop(lib, 'name', lslname);
elseif ~isempty(lsltype)
    result = lsl_resolve_byprop(lib, 'type', lslname);
elseif ~isempty(lslname)
    result = lsl_resolve_byprop(lib, 'name', lsltype);    
else
    error('Both lslname and lsltype cannot be empty');
end;

if isempty(result)
    error( [ 'Cannot find stream.' 10 'Make sure you have the right lslname & lsltype' 10 'Make sure LSL Lab Recorder can see the stream' ]);
end;
