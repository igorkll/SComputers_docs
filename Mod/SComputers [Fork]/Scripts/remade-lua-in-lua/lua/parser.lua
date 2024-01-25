ll_Parser = {
    current = 0,
    line = 1,
    tokens = nil,
    
    precedence = {
        ["and"] = {prec=2, assoc='left'},
        ["or"] = {prec=2, assoc='left'},

        LESS = {prec=5, assoc='left'},
        LESS_EQUAL = {prec=5, assoc='left'},
        GREATER = {prec=5, assoc='left'},
        GREATER_EQUAL = {prec=5, assoc='left'},
        DOUBLE_EQUALS = {prec=5, assoc='left'},
        NOT_EQUAL = {prec=5, assoc='left'},

        CONCAT = {prec=10, assoc='left'},

        PLUS = {prec=20, assoc='left'},
        MINUS = {prec=20, assoc='left'},

        STAR = {prec=30, assoc='left'},
        SLASH = {prec=30, assoc='left'},
        PRECENTAGE = {prec=30, assoc='left'},

        UP = {prec=40, assoc='right'}
    }
}


---Parses tokens and returns a tree
---@param tokens table "Array table of tokens"
---@return table "Tree"
function ll_Parser:parse(tokens)
    self.current = 1
    self.line = 1
    self.tokens = tokens

    return self:parseChunk()
end

local function addInfo(self, tbl)
    tbl.line = self.line
    return tbl
end

function ll_Parser:parseChunk()
    local statements = {}
    local parsed

    while self:available() do
        parsed = false

        if self:match("return") then
            self:match("SEMICOLON")
            if self:available() then
                local node = addInfo(self, {type="return", values=self:parseExprList()})
                self:match("SEMICOLON")
                if self:available() then error("Return statement must be the last statement in the block") end
                statements[#statements+1] = node
            else
                statements[#statements+1] = addInfo(self, {type="return", values={nil}})
            end
            parsed = true
        end

        if not parsed then
            self.line = self:peek().line
            statements[#statements+1] = self:parseStatement()
        end

        self:match("SEMICOLON")
    end

    return addInfo(self, {type="chunk", statements=statements})
end

function ll_Parser:parseBlock(token_type, ...)
    local token_type = token_type or "end"
    local statements = {}
    local parsed

    while not self:match(token_type, ...) do
        parsed = false

        if self:match("return") then
            self:match("SEMICOLON")
            if not self:tokenOneOf(self:peek(), token_type, ...) then
                local node = addInfo(self, {type="return", values=self:parseExprList()})
                self:match("SEMICOLON")
                if not self:tokenOneOf(self:peek(), token_type, ...) then error("Return statement must be the last statement in the block") end
                statements[#statements+1] = node
            else
                statements[#statements+1] = addInfo(self, {type="return", values={nil}})
            end
            parsed = true
        end

        if self:match("break") then
            self:match("SEMICOLON")
            if not self:tokenOneOf(self:peek(), token_type, ...) then
                error("Break statement must be the last statement in the block")
            else
                statements[#statements+1] = addInfo(self, {type="break"})
            end
            parsed = true
        end

        if not parsed then
            self.line = self:peek().line
            statements[#statements+1] = self:parseStatement()
        end

        self:match("SEMICOLON")
    end

    return addInfo(self, {type="block", statements=statements})
end


function ll_Parser:parseStatement()
    if self:match("do") then return addInfo(self, {type="do", body=self:parseBlock()}) end

    if self:match("debugdmpenvstack") then return addInfo(self, {type="debugdmpenvstack"}) end

    if self:match("while") then
        local expr = self:parseExpr()
        self:consume("do", "Expected 'do' after while")
        return addInfo(self, {type="while", expr=expr, body=self:parseBlock()})
    end

    if self:match("repeat") then
        local body = self:parseBlock('until')
        --self:consume("until", "Expected 'until' after repeat body") --consumed by parseBlock
        local expr = self:parseExpr()
        return addInfo(self, {type="repeat", expr=expr, body=body})
    end

    if self:match("if") then
        local expr = self:parseExpr()
        self:consume("then", "Expected 'then' after if")

        local main_body = self:parseBlock('end', 'elseif', 'else')
        local clauses = {{expr=expr, body=main_body}}
        local else_body = nil

        while self:tokenOneOf(self:prev(), 'elseif', 'else') do
            local ttype = self:prev().type
            local subexpr

            if ttype == 'elseif' then
                subexpr = self:parseExpr()
                self:consume("then", "Expected 'then' after 'elseif'")
            end

            local body = self:parseBlock('end', 'elseif', 'else')
            
            if ttype == 'elseif' then clauses[#clauses+1] = {expr=subexpr, body=body}
            elseif ttype == 'else' then else_body = body end

        end

        return addInfo(self, {type="if", expr=expr, clauses=clauses, else_body=else_body})
    end

    if self:match("for") then

        -- standard for loop
        if self:peek(1).type == "EQUALS" then
            local var_name = self:consume("identifier", "Expected variable name after for").lexeme
            self:consume("EQUALS", "Expected '=' after variable name")
            local start = self:parseExpr()
            self:consume("COMMA", "Expected ',' after for loop start")
            local end_loop = self:parseExpr()

            local step
            if self:match("COMMA") then
                step = self:parseExpr()
            else
                step = addInfo(self, {type="literal", value=1})
            end

            self:consume("do", "Expected 'do' after for loop")

            local body = self:parseBlock()
            return addInfo(self, {type="for", var_name=var_name, start=start, end_loop=end_loop, step=step, body=body})
        end

        -- foreach loop
        local ids = self:parseIdList()
        self:consume("in", "Expected 'in' after for loop variable names")

        local exprs = self:parseExprList()
        self:consume("do", "Expected 'do' after for loop")

        local body = self:parseBlock()
        return addInfo(self, {type="foreach", variables=ids, expressions=exprs, body=body})
    end

    if self:match("function") then
        local func_name = self:parseFunctionName()
        local func_value = self:parseFunctionBody()

        if func_name.method then
            table.insert(func_value.arg_names, 1, "self")
        end

        func_name.node.value = func_value

        return func_name.node
    end

    if self:match("local") then

        if self:match("function") then
            local name = self:consume("identifier", "Expected function name").lexeme
            local func_value = self:parseFunctionBody()

            return addInfo(self, {type="declare_local", names={name}, values={func_value}})
        end

        local idlist = self:parseIdList()
        local init_values

        if self:match("EQUALS") then
            init_values = self:parseExprList()
        else
            init_values = {}
        end

        return addInfo(self, {type="declare_local", names=idlist, values=init_values})

    end


    local func_call = self:parseCall()
        
    if func_call.type == "call" or func_call.type == "get_call" then
        return func_call
    end

    local exprs = {func_call}

    if func_call.type ~= "get" and func_call.type ~= "variable" then
        error("[Line " .. self.line .. "] Expected a statement")
    end
    self:match("COMMA")

    if not self:check("EQUALS") then
        repeat
            local expr = self:parseCall()
            if expr.type ~= "get" and expr.type ~= "variable" then
                error("[Line " .. self.line .. "] Expected a statement")
            end
            exprs[#exprs+1] = expr
        until not self:match("COMMA")
    end

    self:consume("EQUALS", "Expected '=' after variable list")
    local init_values = self:parseExprList()

    return addInfo(self, {type="assign_expr", exprs=exprs, values=init_values})
end

function ll_Parser:parseIdList()
    local names = {}

    repeat
        names[#names+1] = self:consume("identifier", "Expected variable name after ','").lexeme
    until not self:match("COMMA")

    return names
end

function ll_Parser:parseFunctionName()
    local names = {}

    repeat
        names[#names+1] = self:consume("identifier", "Expected variable name after '.'").lexeme
    until not self:match("DOT")

    local method = false
    if self:match("COLON") then
        method = true
        names[#names+1] = self:consume("identifier", "Expected variable name after ':'").lexeme
    end

    if #names == 1 then
        return addInfo(self, {node=addInfo(self, {type="assign", name=names[1]}), method=method})
    end

    local tree = addInfo(self, {type="get", from=addInfo(self, {type="variable", name=names[1]}), index=addInfo(self, {type="literal", value=names[2]})})
    
    if #names > 2 then
        for i=3, #names do
            tree = addInfo(self, {type="get", from=tree, index={type="literal", value=names[i]}})
        end
    end
    return addInfo(self, {node=addInfo(self, {type="set", in_value=tree.from, index=tree.index}), method=method})
end

function ll_Parser:parseExprList()
    local exprs = {}

    repeat
        exprs[#exprs+1] = self:parseExpr()
    until not self:match("COMMA")

    return exprs
end

function ll_Parser:parseExpr()
    return self:parseBinOp(0)
end

function ll_Parser:parseBinOp(min_prec)
    local left = self:parseCall()

    while true do
        if not self:available() then break end
        local op_token = self:peek()
        if not self.precedence[op_token.type] then break end -- not an operator
        local prec_data = self.precedence[op_token.type]
        if prec_data.prec < min_prec then break end -- lower precedence, so break

        -- consume op token
        self.current = self.current + 1

        local next_prec = prec_data.assoc == 'left' and prec_data.prec + 1 or prec_data.prec
        local right = self:parseBinOp(next_prec)

        left = addInfo(self, {type="operation", operator=op_token.type, left=left, right=right})
    end

    return addInfo(self, left)
end


function ll_Parser:parseCall()
    local left = self:parsePrimaryExpr()

    while true do
        if self:match("OPEN_PAREN") then
            left = addInfo(self, {type="call", callee=left, args=self:parseArgs()})

        elseif self:match("OPEN_BRACE") then
            left = addInfo(self, {type="call", callee=left, args={self:parseTableConstructor()}})

        elseif self:match("string") then
            left = addInfo(self, {type="call", callee=left, args={addInfo(self, {type='literal', value=self:prev().literal})}})

        elseif self:match("COLON") then
            local idx = self:consume("identifier", "Expected function name after ':'").lexeme
            self:consume("OPEN_PAREN", "Expected '(' after function name")
            local args = self:parseArgs()
            left = addInfo(self, {type="get_call", callee=left, index=idx, args=args})

        elseif self:match("DOT") then
            local idx = self:consume("identifier", "Expected field name after '.'")
            left = addInfo(self, {type="get", from=left, index=addInfo(self, {type="literal", value=idx.lexeme})})

        elseif self:match("OPEN_SQUARE") then
            local idx = self:parseExpr()
            self:consume("CLOSE_SQUARE", "Expected ']' after indexing expression")
            left = addInfo(self, {type="get", from=left, index=idx})
        else
            break
        end
    end

    return addInfo(self, left)
end

function ll_Parser:parseArgs()
    local args = {}

    if not self:check("CLOSE_PAREN") then
        repeat
            args[#args+1] = self:parseExpr()
        until not self:match("COMMA")
    end

    self:consume("CLOSE_PAREN", "Expected ')' after parameters")
    return args
end

function ll_Parser:parsePrimaryExpr()
    if self:match("nil") then return addInfo(self, {type="literal", value=nil}) end
    if self:match("string") then return addInfo(self, {type="literal", value=self:prev().literal}) end
    if self:match("number") then return addInfo(self, {type="literal", value=self:prev().literal}) end
    if self:match("true") then return addInfo(self, {type="literal", value=true}) end
    if self:match("false") then return addInfo(self, {type="literal", value=false}) end
    if self:match("function") then return self:parseFunctionBody() end
    if self:match("OPEN_BRACE") then return self:parseTableConstructor() end

    if self:match("identifier") then return addInfo(self, {type="variable", name=self:prev().lexeme}) end
    if self:match("OPEN_PAREN") then 
        local expr = self:parseExpr()
        self:consume("CLOSE_PAREN", "Expected ')' after grouping expression")
        return expr
    end

    if self:match("not") then return addInfo(self, {type="not", value=self:parseBinOp(40)}) end
    if self:match("MINUS") then return addInfo(self, {type="uminus", value=self:parseBinOp(40)}) end
    if self:match("HASHTAG") then return addInfo(self, {type="get_length", value=self:parseBinOp(40)}) end
    if self:match("VARARGS") then return addInfo(self, {type="varargs"}) end

    print(self:peek().type)
    error("Expected expression")
end

function ll_Parser:parseFunctionBody()
    self:consume("OPEN_PAREN", "Expected '(' for function declaration")

    local arg_names = {}
    local varargs = false

    if not self:check("CLOSE_PAREN") then
        repeat
            if self:match("VARARGS") then
                varargs = true
                break
            else
                arg_names[#arg_names+1] = self:consume("identifier", "Expected variable name in function parameter definition").lexeme
            end
        until not self:match("COMMA")
    end

    self:consume("CLOSE_PAREN", "Expected ')' after function parameter definition")
    local body = self:parseBlock()
    body.type = 'chunk'

    return addInfo(self, {type="function", arg_names=arg_names, varargs=varargs, body=body})
end

function ll_Parser:parseTableConstructor()
    local fields = {}

    if not self:check("CLOSE_BRACE") then
        while not self:check('CLOSE_BRACE') do
            fields[#fields+1] = self:parseTableField()

            if not self:check('CLOSE_BRACE') then
                self:consumeOneOf("Expected ',' or ';' after table field value", 'COMMA', 'SEMICOLON')
            end
        end
    end

    self:consume("CLOSE_BRACE", "Expected '}' after table constructor")
    
    return addInfo(self, {type="table", fields=fields})
end

function ll_Parser:parseTableField()
    if self:match("VARARGS") then
        return addInfo(self, {array_item=true, value=addInfo(self, {type='varargs'})})
    end

    if self:match("OPEN_SQUARE") then
        local idx = self:parseExpr()
        self:consume("CLOSE_SQUARE", "Expected ']' after table field key")
        self:consume("EQUALS", "Expected '=' after table field key")
        local value = self:parseExpr()
        return {key=idx, value=value}
    end

    if self:peek(1).type == "EQUALS" then
        local idx = self:consume("identifier", "Expected field name").lexeme
        self:consume("EQUALS", "Expected '=' after table field key")
        local value = self:parseExpr()
        return {key=addInfo(self, {type="literal", value=idx}), value=value}
    end

    local value = self:parseExpr()
    return {array_item=true, value=value}
end

function ll_Parser:match(...)
    local types = {...}

    for _, token_type in ipairs(types) do
        if self:check(token_type) then
            self.current = self.current + 1
            return true
        end
    end

    return false
end

function ll_Parser:check(token_type)
    return self:peek().type == token_type
end

function ll_Parser:tokenOneOf(token, ...)
    local types = {...}

    for _, token_type in ipairs(types) do
        if token.type == token_type then
            return true
        end
    end

    return false
end

function ll_Parser:consume(token_type, err)
    if self:check(token_type) then return self:advance() end
    error("[Line " .. self:peek().line .. "] ".. err ..'\n'..self:peek().type) 
end

function ll_Parser:consumeOneOf(err, ...)
    local types = {...}

    for _, token_type in ipairs(types) do
        if self:check(token_type) then return self:advance() end
    end

    error("[Line " .. self:peek().line .. "] ".. err ..'\n'..self:peek().type)
end

function ll_Parser:peek(offset)
    local offset = offset or 0
    if self.current+offset > #self.tokens then return addInfo(self, {type="EOF"}) end
    return self.tokens[self.current+offset]
end

function ll_Parser:prev()
    return self.tokens[self.current-1]
end

function ll_Parser:available()
    return self:peek().type ~= "EOF"
end

function ll_Parser:advance()
    local token = self.tokens[self.current]
    self.current = self.current + 1
    return token
end

print("ll_Parser loaded")