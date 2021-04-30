local packetDialog = {}
local idToReply

local possibleIdReply = {
    24901,
    24899,
    24898,
    24896,
    24895,
    24893,
    24892,
    38436,
    38437
}

local isDialog = false

function move()
    global:leaveDialog()
end

function NpcDialogRequest(npcId)
    developer:registerMessage("LeaveDialogMessage", CB_LeaveDialog)
    developer:registerMessage("NpcDialogQuestionMessage", CB_NpcDialogQuestionMessage)
    PacketSender("NpcGenericActionRequestMessage", function(msg)
        msg.npcId = npcId
        msg.npcActionId = 3
        msg.npcMapId = map:currentMapId()
        return msg 
    end)
    isDialog = true
    developer:suspendScriptUntil("NpcDialogQuestionMessage", 1000, true)
end

function CB_NpcDialogQuestionMessage(packet)
    developer:unRegisterMessage("NpcDialogQuestionMessage")
    packetDialog = packet
end

function CB_LeaveDialog()
    developer:unRegisterMessage("NpcDialogQuestionMessage")
    isDialog = false
end

function NpcReply(id, speed, tblId)
    if tblId ~= nil then
        for _, v in pairs(packetDialog.visibleReplies) do
            for _, c in pairs(tblId) do
                if v == c then
                    id = v
                    break
                end
            end
        end
    end

    developer:registerMessage("NpcDialogQuestionMessage", CB_NpcDialogQuestionMessage)

    local min, max

    if speed == nil then
        min = 492
        max = 728
    elseif string.lower(speed) == "slow" then
        min = 621
        max = 1149
    elseif string.lower(speed) == "fast" then
        min = 189
        max = 436
    end

    global:delay(GetRandomNumber(min, max))
    --Print(id)
    npc:reply(id)
    developer:suspendScriptUntil("NpcDialogQuestionMessage", 1000, true)
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

function PacketSender(packetName, fn)
    Print("Envoie du packet "..packetName, "packet")
    local msg = developer:createMessage(packetName)

    if fn ~= nil then
        msg = fn(msg)
    end

    developer:sendMessage(msg)
end

function GetRandomNumber(min, max)
    local rand = json.parse(developer:getRequest("http://www.randomnumberapi.com/api/v1.0/random?min="..tostring(min).."&max="..tostring(max).."&count=1"))  
    return rand[1]
end