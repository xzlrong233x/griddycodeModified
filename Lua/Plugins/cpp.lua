--- Highlight Keywords
highlight("alignas", "reserved")
highlight("alignof", "reserved")
highlight("and", "reserved")
highlight("and_eq", "reserved")
highlight("asm", "reserved")
highlight("atomic_cancel", "reserved")
highlight("atomic_commit", "reserved")
highlight("atomic_noexcept", "reserved")
highlight("auto", "reserved")
highlight("bitand", "reserved")
highlight("bitor", "reserved")
highlight("bool", "reserved")
highlight("break", "reserved")
highlight("case", "reserved")
highlight("catch", "reserved")
highlight("char", "reserved")
highlight("char8_t", "reserved")
highlight("char16_t", "reserved")
highlight("char32_t", "reserved")
highlight("class", "reserved")
highlight("compl", "reserved")
highlight("concept", "reserved")
highlight("const", "reserved")
highlight("consteval", "reserved")
highlight("constexpr", "reserved")
highlight("constinit", "reserved")
highlight("const_cast", "reserved")
highlight("continue", "reserved")
highlight("co_await", "reserved")
highlight("co_return", "reserved")
highlight("co_yield", "reserved")
highlight("decltype", "reserved")
highlight("default", "reserved")
highlight("delete", "reserved")
highlight("do", "reserved")
highlight("double", "reserved")
highlight("dynamic_cast", "reserved")
highlight("else", "reserved")
highlight("enum", "reserved")
highlight("explicit", "reserved")
highlight("export", "reserved")
highlight("extern", "reserved")
highlight("false", "reserved")
highlight("float", "reserved")
highlight("for", "reserved")
highlight("friend", "reserved")
highlight("goto", "reserved")
highlight("if", "reserved")
highlight("import", "reserved")
highlight("inline", "reserved")
highlight("int", "reserved")
highlight("long", "reserved")
highlight("module", "reserved")
highlight("mutable", "reserved")
highlight("namespace", "reserved")
highlight("new", "reserved")
highlight("noexcept", "reserved")
highlight("not", "reserved")
highlight("not_eq", "reserved")
highlight("nullptr", "reserved")
highlight("operator", "reserved")
highlight("or", "reserved")
highlight("or_eq", "reserved")
highlight("private", "reserved")
highlight("protected", "reserved")
highlight("public", "reserved")
highlight("reflexpr", "reserved")
highlight("register", "reserved")
highlight("reinterpret_cast", "reserved")
highlight("requires", "reserved")
highlight("return", "reserved")
highlight("short", "reserved")
highlight("signed", "reserved")
highlight("sizeof", "reserved")
highlight("static", "reserved")
highlight("static_assert", "reserved")
highlight("static_cast", "reserved")
highlight("struct", "reserved")
highlight("switch", "reserved")
highlight("synchronized", "reserved")
highlight("template", "reserved")
highlight("this", "reserved")
highlight("thread_local", "reserved")
highlight("throw", "reserved")
highlight("true", "reserved")
highlight("try", "reserved")
highlight("typedef", "reserved")
highlight("typeid", "reserved")
highlight("typename", "reserved")
highlight("union", "reserved")
highlight("unsigned", "reserved")
highlight("using", "reserved")
highlight("virtual", "reserved")
highlight("void", "reserved")
highlight("volatile", "reserved")
highlight("wchar_t", "reserved")
highlight("while", "reserved")
highlight("xor", "reserved")
highlight("xor_eq", "reserved")

--- Arithmetic Operators
highlight("+", "operator")
highlight("-", "operator")
highlight("*", "operator")
highlight("/", "operator")
highlight("%", "operator")
highlight("**", "operator")
highlight("++", "operator")
highlight("--", "operator")

--- Assignment Operators
highlight("=", "operator")
highlight("+=", "operator")
highlight("-=", "operator")
highlight("*=", "operator")
highlight("/=", "operator")
highlight("%=", "operator")

--- Comparison Operators
highlight("==", "operator")
highlight("!=", "operator")
highlight(">", "operator")
highlight("<", "operator")
highlight(">=", "operator")
highlight("<=", "operator")

--- Logical Operators
highlight("&&", "operator")
highlight("||", "operator")
highlight("!", "operator")

--- Bitwise Operators
highlight("&", "operator")
highlight("|", "operator")
highlight("^", "operator")
highlight("~", "operator")
highlight("<<", "operator")
highlight(">>", "operator")

--- Special Characters
highlight("{", "binary")
highlight("}", "binary")
highlight("[", "binary")
highlight("]", "binary")
highlight("(", "binary")
highlight(")", "binary")
highlight(";", "binary")
highlight(",", "binary")

--- Strings
highlight_region("\"", "\"", "string")
highlight_region("'", "'", "string")

--- Comments
highlight_region("//", "", "comments", true)
highlight_region("/*", "*/", "comments", false)

--- Added functions

function make_iter_table(iter)
    local t = {}
    for i in iter do
        table.insert(t,i)
    end
    return t
end

function extand(orgin_table,added_table)
    for key, value in pairs(added_table) do
        table.insert(orgin_table,value)
    end
end

--- Autocomplete
--- also have bug
function detect_functions(content, line, column)
    local functionNames = {}
    functionNames[0] = {}
    local tier = 0
    local lindex = 0
    local end_list = {}
    local sel_tier = 0
    for lin in content:gmatch("[^\r\n]+") do
        -- Match function declarations
        local resultTyp,functionName = lin:match("%s*([%w_:]+)%s+([%w_:]+)%s*%([^%)]*%)%s*%{?")
        if functionName then
            table.insert(functionNames[tier], functionName)
        end
        for restype, value in lin:gmatch("%s*([%w_:]+)%s+([%w_:]+)%s*%(%)%s*;") do
            if (value and restype) then
                table.insert(functionNames[tier], functionName)
            end
        end
        if lin:find("{") then
            tier = tier + 1
        end
        if lin:find("}") then
            tier = tier - 1
            if tier < 0 then
                tier = 0
            end
        end
        if lindex == line then
            sel_tier = tier
            break
        end
        lindex = lindex + 1
    end

    for index, value in pairs(functionNames) do
        if index <= sel_tier then
            extand(end_list,value)
        end
    end

    return end_list
end

KeywordList = {"struct","class","return","continue","break","else","if"}
VarTypeList = {"long","int","char","short","float","double","bool","unsigned"}
WellList = {"define","include"}

function detect_variables(content, line, column)
    local variable_names = {}
    variable_names[0] = {}
    local end_list = {}
    local temvars = {}
    local block_list = {}
    local lines = content:gmatch("[^\r\n]+")
    local lindex = 0
    local tier = 0
    local sel_tier = 0
    for lin in lines do
        lin = lin:gsub("[%*&]","")
        local orgin_lin = lin
        lin = lin:gsub([[%b""]],""):gsub([[%b'']],""):gsub([[//.*]],""):gsub([[/%*.*%*/]],"")
        -- Match variable declarations
        local vt = lin:gsub('for ',''):gmatch("[/t%s]*([%w_:]+)%s+([%w_:,%(%)%{%}%s]+)%s*[=;]")
        for typ,var in vt do
            if (typ and var) then
                var = trim(var)
                if var:find("%(") and (var:find("%(%)") or var:match("[/t%s]*([%w_:]+)%s+([%w_:]+)%s*[=;]")) then
                    goto continue
                end
                for _,typee in pairs(KeywordList) do
                    if typee == typ then
                        if typee ~= "auto" then
                            goto continue
                        else
                        end
                    end
                end
                local removed_var = var:gsub("%b()",""):gsub("%b{}",""):gsub("%b[]",""):gsub("%s","")
                if lin:find("for") and lin:find("for") < lin:find(var) then
                    extand(block_list,splitstr(removed_var,','))
                    -- print(removed_var)
                    goto continue
                end
                extand(temvars,splitstr(removed_var,','))
            end
            ::continue::
        end
        local cas_sa = lin:match("class%s+([%w_]+)%s*{")
        if cas_sa then
            table.insert(temvars,cas_sa)
        end
        local well_define = lin:match("#define ([%w_:]+) [^\r\n]+")
        if well_define then
            table.insert(temvars,well_define)
            --print(well_define)
        end
        if lin:find("{") then
            extand(variable_names[tier],temvars)
            tier = tier + 1
            temvars = {}
            variable_names[tier] = {}
            extand(temvars,block_list)
            block_list = {}
            if lin:find("%(") and lin:match("%(([^%)]*)%)") then
                local func_vars = lin:match("%(([^%)]*)%)")
                if not func_vars:find(";") then
                    for typ,val in func_vars:gmatch("[%s]*([%w_:]+)%s+([%w_:]+)%s*[=,]?") do
                        table.insert(temvars,val)
                    end
                end
            end
        end
        if lindex == line then
            if lin:find("^#") and not (lin:find(" ") and lin:find(" ") < column) then
                return WellList
            end
            if lin:find("^#include ") and lin:find('["<]') >= column and lin:find('[">]') < column then
                -- TODO - read default include folder
            end
            string.
            sel_tier = tier
            if lin:find("{") and lin:find("{") > column then
                sel_tier = tier - 1
            end
            extand(variable_names[sel_tier],temvars)
            break
        end
        if lin:find('}') then
            temvars = {}
            tier = tier - 1
            if tier < 0 then
                tier = 0
            end
        end
        lindex = lindex + 1
    end

    --[[print("tier",sel_tier)
            for index, value in pairs(variable_names) do
                print(index," -> ")
                for _, vv in ipairs(value) do
                    print(vv)
                end
            end]]

    for index, value in pairs(variable_names) do
        if index <= sel_tier then
            extand(end_list,value)
        end
    end

    extand(end_list,VarTypeList)
    extand(end_list,KeywordList)

    return end_list
end