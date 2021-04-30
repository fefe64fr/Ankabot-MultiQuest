local tblMap = {
    153878788,
    154010372,
    154010884,
    154010885,
    154011397,
    154011398,
    154010886,
    154010374,
    154010373
}

function move()
    RoadZone(tblMap)
end

function RoadZone(tblMapId)
    if tblMapId.mapIdToGo == nil then
        tblMapId.mapIdToGo = 0
    end

    local condition = function()
        return map:currentMapId() == tblMapId.mapIdToGo or tblMapId.mapIdToGo == 0
    end

    if condition() then
        --Print("Get next rand roadMapId")
        while condition() do
            local rand = GetRandomNumber(1, #tblMapId)
            Print(tblMapId.mapIdToGo)
            tblMapId.mapIdToGo = tblMapId[rand]
            global:delay(200)
        end
        --Print("Next roadMapId = "..tblMapId.mapIdToGo)
        if not map:loadMove(tblMapId.mapIdToGo) then
            Print("Impossible de charger le trajet jusqu'a la mapId : "..tblMapId.mapIdToGo, "RoadZone", "error")
        end
    end

    map:moveRoadNext()
end

function Print(msg, header, msgType)
    local prefabStr = ""

    if header ~= nil then
        prefabStr = "["..string.upper(header).."] "..msg
    else
        prefabStr = msg
    end

    if msgType == nil then
        global:printSuccess(prefabStr)
    elseif string.lower(msgType) == "normal" then
        global:printMessage(prefabStr)
    elseif string.lower(msgType) == "error" then
        global:printError("[ERROR]["..header.."] "..msg)
    end
end

function GetRandomNumber(min, max)
    local rand = json.parse(developer:getRequest("http://www.randomnumberapi.com/api/v1.0/random?min="..tostring(min).."&max="..tostring(max).."&count=1"))  
    return rand[1]
end