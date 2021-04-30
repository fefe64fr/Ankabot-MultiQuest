local currentDirectory = "E:\\Dofus botting\\Scripts\\Trajets\\AnkaBot\\Ankabot-MultiQuest\\"

local QUEST = dofile(currentDirectory.."QuestInfo.lua")

local QuestList = {}
local currentQuest, F_step

local roadLoaded, selectedStep = "roadLoaded", "selectedStep"
local scriptInit = false

local selectedQuestToGo = false

function move()
    if not scriptInit then
        ClearScript()
        developer:registerMessage("QuestListMessage", CB_QuestListMessage)
        developer:registerMessage("QuestStepInfoMessage", test)
        LoadHistoricalQuestList()
        global:addInMemory(roadLoaded, false)
        global:addInMemory(selectedStep, false)
        scriptInit = true
    end

    if not selectedQuestToGo then
        SelectQuestToGo()
        selectedQuestToGo = true
    end
    
    if not global:remember(selectedStep) then
        if CheckIfQuestActive(currentQuest.questId) then
            F_step = SelectStepToGo(GetCurrentStep())
            global:editInMemory(selectedStep, true)           
        else
            F_step = currentQuest.stepInfo.START
            global:editInMemory(selectedStep, true)
        end
    end

    if global:remember(selectedStep) and F_step ~= nil then
        Print(tostring(global:remember(selectedStep)))
        Print(F_step.displayInfo, currentQuest.name)
        F_step.EXECUTE()
    else
        Print("Aucune étape séléctionner", "QuestManager", "error")
        ClearScript()
    end
end

-- Gestion packet et script

function ScriptManager()
    if not global:isScriptPlaying() then
        Print("ClearScript", "end")
        ClearScript()
    end
end

function ClearScript()
    developer:unRegisterMessage("GameMapMovementConfirmMessage")
    developer:unRegisterMessage("QuestListMessage")
    global:deleteAllMemory()
end

function CB_QuestListMessage(packet)
    Print("Packet QuestListMessage reçu", "packet")
    QuestList.activeQuests = packet.activeQuests
    QuestList.finishedQuestsIds = packet.finishedQuestsIds
    QuestList.finishedQuestsCounts = packet.finishedQuestsCounts
    QuestList.reinitDoneQuestsIds = packet.reinitDoneQuestsIds
end

function test(packet)
    Print("Packet QuestStepInfoMessage reçu", "packet")

    for _, v in pairs(QuestList.activeQuests) do
        --Print(developer:typeOf(v))
        if v.questId == packet.infos.questId then
            Print("Objectif de quête mis a jour", "dev")
            v.objecttives = packet.infos.objecttives
            break
        end
    end

end

function PacketSender(pcktName, content)
    local msg = developer:createMessage(pcktName)
    if content ~= nil then
        msg = content
    end
    developer:sendMessage(msg)
end

function LoadHistoricalQuestList()
    local packet = developer:historicalMessage("QuestListMessage")
    QuestList.activeQuests = packet[1].activeQuests
    QuestList.finishedQuestsIds = packet[1].finishedQuestsIds
    QuestList.finishedQuestsCounts = packet[1].finishedQuestsCounts
    QuestList.reinitDoneQuestsIds = packet[1].reinitDoneQuestsIds
end

-- Gestion des quête

function MoveNext()
    --Print("Try moveNext")
    if global:remember(roadLoaded) and selectedStep then
        map:moveRoadNext()
    else
        return move()
    end
end

function EndStep(typeMove, dir)
    Print("Etape terminée", currentQuest.name)
    global:editInMemory(selectedStep, false)
    global:editInMemory(roadLoaded, false)
    F_step = nil
    Print(tostring(global:remember(selectedStep)))

    if typeMove == nil then
        return move()
    elseif string.lower(typeMove) == "door" then
        map:door(dir)
    elseif string.lower(typeMove) == "npcreply" then
        NpcReply(dir)
    end

    return move()
end

function EndQuest(typeMove, dir)
    Print("Quête terminée !", currentQuest.name)
    selectedQuestToGo = false
    global:editInMemory(selectedStep, false)
    global:editInMemory(roadLoaded, false)
    F_step = nil

    if typeMove == nil then
        return move()
    elseif string.lower(typeMove) == "door" then
        map:door(dir)
    elseif string.lower(typeMove) == "npcreply" then
        NpcReply(dir)
    end

    return move()
end

function GetCurrentStep()
    for _, v in pairs(QuestList.activeQuests) do
        if v.questId == currentQuest.questId then
            for _, v2 in pairs(v.objecttives) do
                if v2.objecttiveStatus then
                    --Print(v2.objecttiveId)
                    return v2.objecttiveId
                end
            end
        end
    end
end

function SelectStepToGo(stepId)
    for k, v in pairs(currentQuest.stepInfo) do
        if tostring(k) == tostring(stepId) then
            return v
        end
    end
end

function SelectQuestToGo()
    for k, v in pairs(QUEST) do
        if not CheckIfQuestFinish(v.questId) then
            local canSelect = true

            if not IsNul(v.requiredFinishedQuest) then
                for _, reqId in pairs(v.requiredFinishedQuest) do
                    if not CheckIfQuestFinish(reqId) then
                        canSelect = false
                    end
                end
            end

            if canSelect then
                Print("Quête séléctionner", k)
                v.name = k
                currentQuest = v
                break
            end
        else
            Print("La quête est fini", k)
        end
    end
end

function CheckIfQuestActive(questId)
    if not IsNul(QuestList.activeQuests) then
        for _, v in pairs(QuestList.activeQuests) do
            if v.questId == questId then
                return true
            end
        end
    end
    return false
end

function CheckIfQuestFinish(questId)
    if not IsNul(QuestList.finishedQuestsIds) then
        for _, v in pairs(QuestList.finishedQuestsIds) do
            if v == questId then
                return true
            end
        end
    end
    return false
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

function IsNul(var)
    return var == nil 
end

function NpcReply(id, speed)
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
    npc:reply(id)
end

function GetRandomNumber(min, max)
    local rand = json.parse(developer:getRequest("http://www.randomnumberapi.com/api/v1.0/random?min="..tostring(min).."&max="..tostring(max).."&count=1"))  
    return rand[1]
end