local function byteToBits(byte)
    local bits = ""
    for i = 7, 0, -1 do
        bits = bits .. ((byte >> i) & 1)
    end
    return bits
end

local function stringToBits(str)
    checkArg(1, str, "string")
    local bits = ""
    for i = 1, str:len() do
        bits = bits .. byteToBits(string.byte(string.sub(str, i, i)))
    end
    return bits
end

local base64 = {
    encode = function(text)
        checkArg(1, text, "string")
        local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local bits = stringToBits(text)
        --print("bits=" .. bits)

        local b64 = ""
        repeat
            local segment = bits:sub(1, 24)
            --print("segment=" .. segment)
            if segment:len() ~= 24 then
                repeat
                    segment = segment .. "00"
                    --print("segment=" .. segment)
                until segment:len() == 24
            end

            local b64segment = ""
            for i = 1, 24, 6 do
                local idx = tonumber(segment:sub(i, 5+i), 2)
                if (not idx) or (idx == 0) then
                    break
                end
                idx = idx + 1
                b64segment = b64segment .. b64chars:sub(idx, idx)
            end
            --print("b64segment=" .. b64segment)

            b64 = b64 .. b64segment
            bits = bits:sub(25, -1)
        until bits == ""
        --print("b64=" .. b64)

        for i = 1, b64:len() % 4 do
            b64 = b64 .. "="
        end
        if b64:sub( -3, -1) == "===" then
            b64 = b64:sub(1, -3)
        end

        return b64
    end,

    decode = function (b64)
        checkArg(1, b64, "string")
        local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local bits = ""

        for i = 1, b64:len() do
            local char = b64:sub(i, i)
            if char == "=" then
                bits = bits:sub(1, -3)
                break
            end
            local idx = b64chars:find(char, 1, true) - 1
            bits = bits .. string.sub(byteToBits(idx), 3, 8)
        end

        local text = ""
        repeat
            local segment = bits:sub(1, 8)
            local byte = tonumber(segment, 2)
            text = text .. string.char(byte)
            bits = bits:sub(9, -1)
        until bits == ""

        return text
    end
}

return base64