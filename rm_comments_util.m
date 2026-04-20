function cleanJson = rm_comments_util(json)
    % Get all field names
    fields = fieldnames(json);

    % Loop through each field
    for i = 1:length(fields)
        fieldName = fields{i};

        % If the field starts with 'comment', remove it
        if startsWith(fieldName, 'comment', 'IgnoreCase', true)
            json = rmfield(json, fieldName);
        % If the field is a struct, recurse
        elseif isstruct(json.(fieldName))
            json.(fieldName) = rm_comments_util(json.(fieldName));
        % If the field is an array of structs, recurse on each element
        elseif iscell(json.(fieldName)) && ~isempty(json.(fieldName)) && isstruct(json.(fieldName){1})
            for j = 1:length(json.(fieldName))
                json.(fieldName){j} = rm_comments_util(json.(fieldName){j});
            end
        end
    end

    cleanJson = json;
end
