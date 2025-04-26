--- Highligth Keywords
highlight("import", "reserved")
highlight("from", "reserved")
highlight("while", "reserved")
highlight("if", "reserved")
highlight("else", "reserved")
highlight("elif", "reserved")

highlight("False", "binary")
highlight("True", "binary")
highlight("None", "binary")

--- Arithmetic Operators
highlight("+", "operator")
highlight("-", "operator")
highlight("*", "operator")
highlight("/", "operator")
highlight("%", "operator")
highlight("**", "operator")
highlight("//", "operator")

--- Assignment Operators
highlight("=", "operator")
highlight("+=", "operator")
highlight("!=", "operator")
highlight("*=", "operator")
highlight("/=", "operator")
highlight("%=", "operator")
highlight("//=", "operator")
highlight("**=", "operator")
highlight("&=", "operator")
highlight("|=", "operator")
highlight("^=", "operator")
highlight(">>=", "operator")
highlight("<<=", "operator")

--- Comparison Operators
highlight("==", "operator")
highlight("!=", "operator")
highlight(">", "operator")
highlight("<", "operator")
highlight(">=", "operator")
highlight("<=", "operator")

--- Logical Operators
highlight("and", "reserved")
highlight("or", "reserved")
highlight("not", "reserved")

--- Membership Operators
highlight("in", "reserved")

--- Special Characters
highlight("{", "binary")
highlight("}", "binary")
highlight("[", "binary")
highlight("]", "binary")

--- Strings
highlight_region("'", "'", "string")
highlight_region('"', '"', "string")
highlight_region('"""', '"""', "string")

--- User Comments
highlight_region("#", "", "comments", true)

--- Comments
add_comment("WHAT THE FUCK STOP")
add_comment("this shi 100% breaking")
add_comment("Tip: remove all spaces and tabs")
add_comment("You have to avoid Python to make your script fast")
add_comment("🚨🚨🚨 🐌🐌🐌 🚨🚨🚨")
add_comment("Do NOT run Python on your computer. I did and ALMOST died")
add_comment("Python is deprecated, uninstall python and use anything else instead.")
add_comment("Stop using black, its name is racist!")
add_comment(
    "For more annoyance, please use PyLint and enable C0114, " 
    .. "C0115, and C0116. You'll hate me for it.")
add_comment("Waiter, waiter, more useless docstrings for this self-explanatory code!")
add_comment(
    "You have to document every variable, function, "
    .. "module, and class in Python because self-explanatory code is not enough")

--- added function
function make_iter_table(iter)
    local t = {}
    for i,j in iter do
        local p = i
        if j ~= nil then
            p = {i,j}
        end
        table.insert(t,p)
    end
    return t
end

function extand(orgin_table,added_table)
    for key, value in pairs(added_table) do
        table.insert(orgin_table,value)
    end
end

function IsBlockStartPoint(str)
    return str:gsub("[\t%s]",''):find(':',-1) == #str:gsub("[\t%s]",'')
end

function mk_string_em(content)
    for i=1,#content do
        c = content:sub(i,i+1)

    end
end

function split(input,sep)
    local tb = make_iter_table(input:gmatch("(.-)"..sep))
    local n = input:gsub("(.-)"..sep,"")
    table.insert(tb,n)
    return tb
end

function trim(str)
    local n = str:gsub("^%s+","")
    n = n:gsub("%s+$","")
    return n
end

function split_trim(str,sep)
    local n = split(str,sep)
    for key, value in pairs(n) do
        n[key] = trim(value)
    end
    return n
end

--- Autocomplete
--- I only achieve following expression:
---- 1. function arg
---- 2. block var (like while, with, for, etc)
---- 3. walrus operator (inline like a = 1 if (v := 2) else 3 will add {v})
---- 4. assign chain (like a = b = c = 1 will add {a,b,c})
--- it don't test more, may have unexpected bug.
--- by xzlrong233x 2025/4/26
DefinedV = {"__name__", "__annotations__", "__build_class__", "__builtins__", "__cached__", "__dict__", "__doc__", "__file__", "__import__", "__loader__", "__name__", "__package__", "__path__", "__spec__"}

function detect_functions(content,line,column)
    local functionNames = {"globle"}
    local tem_func = {}
    local under_def_line = false
    local cursep = 0
    local count = 0
    for nline in content:gmatch("[^\r\n]*") do
        local block_sep = #(nline:match('[\t%s]*') or "")
        -- Meet the no space line reset temp
        if under_def_line then
            tem_func[block_sep] = {}
            under_def_line = false
        end
        -- Match the "def" keyword for regular functions
        local functionName = nline:match("def%s+([%w_]+)%s*%(")
        if not functionName then
            -- Match the "async def" pattern for asynchronous functions
            functionName = nline:match("async%s+def%s+([%w_]+)%s*%(")
        end

        if functionName then
            under_def_line = true
            if block_sep == 0 then
                table.insert(functionNames, functionName)
            else
                if not tem_func[block_sep] then
                    tem_func[block_sep] = {}
                end
                table.insert(tem_func[block_sep],functionName)
            end
        end
        if count == line then
            cursep = block_sep
        end
        count = count + 1
    end
    for index,value in pairs(tem_func) do
        if index - 1 < cursep then
            extand(functionNames,value)
        end
    end

    return functionNames
end

function detect_variables(content,line,column)
    local variable_names = {}
    local lines = content:gmatch("[^\r\n]*")
    local line_count = 0
    local temp_var = {}
    local last_block_sep = 0
    temp_var[0] = {}
    local block_temp = {}
    local under_point = false
    local start_str_block = false
    for nline in lines do
        --- check if the line is empty or a comment
        if start_str_block then
            if nline:find("'''") or nline:find('"""') then
                start_str_block = false
            end
            goto continue2
        end
        if nline:find("'''") or nline:find('"""') then
            start_str_block = true
        end
        -- remove variable def in a string
        nline = nline:gsub("'.-'",'')
        nline = nline:gsub('".-"','')
        local block_sep = #nline:match('[\t%s]*')
        --- remove out sep temp var
        if under_point then
            local clear_ind = {}
            for key, _ in pairs(temp_var) do
                if key > block_sep then
                    table.insert(clear_ind,key)
                end
            end
            for _, value in pairs(clear_ind) do
                temp_var[value] = {}
            end
            temp_var[block_sep] = {}
            under_point = false
        end
        --- added start var
        if block_sep ~= last_block_sep and #block_temp > 0 then
            extand(temp_var[block_sep],block_temp)
            block_temp = {}
        end
        -- check block start variables, like "def ggg(j,k,l)" will add variable {j,k,l} and "while (a := len(aaa))" will add {a}
        if IsBlockStartPoint(nline) then
            under_point = true
            local rem_space = nline:gsub('[%s\t]+','',1)
            if rem_space:find("def") == 1 or rem_space:find("async def") == 1 then
                block_temp = make_iter_table(nline:match("%((.-)%)"):gmatch("([%w_0-9]+)%s*=?%s*[^,]*"))
            elseif rem_space:match("with%s+.-%s+as%s+(.-):") then
                extand(block_temp,split_trim(rem_space:match("with%s+.-%s+as%s+(.-):"),","))
            elseif rem_space:match("for%s+([%w_,0-9]+)%s-in.-:") then
                extand(block_temp,split_trim(rem_space:match("for%s+([%w_,0-9]+)%s-in.-:"),","))
            elseif nline:find(":=") then
                block_temp = split_trim(nline:match("([%w_,0-9]+)%s*:=%s*[^,]*"),",")
            end
        else
            --- split line by ";" and check each split
            for key, value in pairs(split_trim(nline,";")) do
                if value:match("[^=!><]=[^=!><]") == nil then ---when no assign
                    ---print(value)
                    goto continue
                end
                local inline_var = {}
                local split_eq = split_trim(value,"%f[:=><!]=%f[^:=><!]")
                --- split the assign chain
                for k, v in pairs(split_eq) do
                    if k ~= #split_eq then --- the last element is not assign
                        local ot = v:match("[%w_,0-9]+$")
                        extand(inline_var,split_trim(ot,","))
                    end
                end
                --- check walrus operator
                for _, __ in value:gmatch("([%w_,0-9]+)%s-:=%s-([%w_,0-9]+)") do
                    extand(inline_var,split_trim(_,","))
                end
                if block_sep == 0 then
                    -- globle variables
                    extand(variable_names,inline_var)
                else
                    -- local variables
                    if not temp_var[block_sep] then
                        -- init Current table
                        temp_var[block_sep] = {}
                    end
                    extand(temp_var[block_sep],inline_var)
                end
                ::continue::
            end
        end
        -- add same sep
        if line_count == line then
            for index,value in pairs(temp_var) do
                if index - 1 < block_sep then
                    extand(variable_names,value)
                end
            end
        end
        ::continue2::
        -- check local variable
        last_block_sep = block_sep
        line_count = line_count + 1;
    end
    extand(variable_names,DefinedV)
    return variable_names
end