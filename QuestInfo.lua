local QUEST = {
    ["Drop pano aventurier"] = {
        questId = 0000000000,
        minLevel = 12,
        bypassCondEndStep = true,
        notStepInfo = true,
        stepInfo = { 
            ["START"] = {
                displayInfo = "Étape 0 / 6 -- Start",
                ["EXECUTE"] = function(stepStartMapId)

                    local objecttives = {
                        {
                            objecttiveId = 1,
                            objecttiveStatus = true
                        },
                        {
                            objecttiveId = 2,
                            objecttiveStatus = true
                        },
                        {
                            objecttiveId = 3,
                            objecttiveStatus = true
                        },
                        {
                            objecttiveId = 4,
                            objecttiveStatus = true
                        },
                        {
                            objecttiveId = 5,
                            objecttiveStatus = true
                        },
                        {
                            objecttiveId = 6,
                            objecttiveStatus = true
                        }
                    }

                    local notZero = function(int)
                        return int > 0
                    end

                    if notZero(inventory:itemCount(2473)) and notZero(inventory:itemCount(2474)) and notZero(inventory:itemCount(2475)) and notZero(inventory:itemCount(2476)) and notZero(inventory:itemCount(2477)) and notZero(inventory:itemCount(2478)) then
                        AddQuestActive(0000000000, objecttives)
                        DeleteActiveQuest(0000000000)
                    else
                        AddQuestActive(0000000000, objecttives)
                    end
                end   
            }, 
            ["1"] = {
                displayInfo = "Étape 1 / 6 -- Drop cape aventurier",
                ["EXECUTE"] = function()
                    local tblMapId = Get_TblZoneSubArea("Incarnam", "Route des âmes")

                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {}
                    }

                    if inventory:itemCount(2473) > 0 then
                        EditQuestObjecttives(0000000000, 1, false)
                    else
                        if InMapChecker(tblMapId) then
                            Fight(confMonster)
                        end                        
                        RoadZone(tblMapId)
                    end
                end
            },
            ["2"] = {
                displayInfo = "Étape 2 / 6 -- Drop coiffe aventurier",
                ["EXECUTE"] = function()
                    local tblMapId = Get_TblZoneSubArea("Incarnam", "Cimetière")

                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {}
                    }

                    if inventory:itemCount(2474) > 0 then
                        EditQuestObjecttives(0000000000, 2, false)
                    else
                        if InMapChecker(tblMapId) then
                            Fight(confMonster)
                        end
                        RoadZone(tblMapId)
                    end
                end
            }, 
            ["3"] = {
                displayInfo = "Étape 3 / 6 -- Drop anneau aventurier",
                ["EXECUTE"] = function()
                    local tblMapId = Get_TblZoneSubArea("Incarnam", "Forêt")

                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {}
                    }

                    if inventory:itemCount(2475) > 0 then
                        EditQuestObjecttives(0000000000, 3, false)
                    else
                        if InMapChecker(tblMapId) then
                            Fight(confMonster)
                        end
                        RoadZone(tblMapId)
                    end
                end
            }, 
            ["4"] = {
                displayInfo = "Étape 4 / 6 -- Drop bottes aventurier",
                ["EXECUTE"] = function()
                    local tblMapId = Get_TblZoneSubArea("Incarnam", "Pâturages")

                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {}
                    }

                    if inventory:itemCount(2476) > 0 then
                        EditQuestObjecttives(0000000000, 4, false)
                    else
                        if InMapChecker(tblMapId) then
                            Fight(confMonster)
                        end
                        RoadZone(tblMapId)
                    end
                end
            },       
            ["5"] = {
                displayInfo = "Étape 5 / 6 -- Drop ceinture aventurier",
                ["EXECUTE"] = function()
                    local tblMapId = Get_TblZoneSubArea("Incarnam", "Lac")

                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {}
                    }

                    if inventory:itemCount(2477) > 0 then
                        EditQuestObjecttives(0000000000, 5, false)
                    else
                        if InMapChecker(tblMapId) then
                            Fight(confMonster)
                        end
                        RoadZone(tblMapId)
                    end
                end
            },       
            ["6"] = {
                displayInfo = "Étape 6 / 6 -- Drop amulette aventurier",
                ["EXECUTE"] = function()
                    local tblMapId = Get_TblZoneSubArea("Incarnam", "Champs")

                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 3,
                        conf = {}
                    }

                    if inventory:itemCount(2478) > 0 then
                        DeleteActiveQuest(0000000000)
                    else
                        if InMapChecker(tblMapId) then
                            Fight(confMonster)
                        end
                        RoadZone(tblMapId)
                    end
                end
            }
        }
    },
    ["L'anneau de tous les dangers"] = {
        questId = 1629,
        stepInfo = {
            ["START"] = {
                displayInfo = "Étape 0 / 10 -- Récupérer la quête",
                stepStartMapId = 153092354,
                ["EXECUTE"] = function(stepStartMapId)    
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        npc:npc(2897 , 3)
                        NpcReply(-1, "slow")
                        NpcReply(-1)
                    else
                        MoveNext()
                    end
                end   
            },           
            ["9655"] = {
                displayInfo = "Étape 1 / 10 -- Monter les éscalier",
                stepStartMapId = 153092354,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        map:door(276)
                    else
                        MoveNext()
                    end
                end
            },
            ["9656"] = {
                displayInfo = "Étape 2 / 10 -- Parler a maître Hoboulo",
                stepStartMapId = 153093380,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        npc:npc(2895 , 3)
                        NpcReply(-1, "slow")
                        NpcReply(-1)
                        NpcReply(-1, "fast")
                    else
                        MoveNext()
                    end
                end
            },
            ["9657"] = {
                displayInfo = "Étape 3 / 10 -- Couper du blé",
                stepStartMapId = 153093380,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        --map:moveToCell(381)
                        map:door(395)
                    else
                        MoveNext()
                    end
                end
            },
            ["9658"] = {
                displayInfo = "Étape 4 / 10 -- Cueillir un ortie",
                stepStartMapId = 153093380,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        --map:moveToCell(271)
                        map:door(258)
                    else
                        MoveNext()
                    end
                end
            },
            ["9659"] = {
                displayInfo = "Étape 5 / 10 -- Couper du bois",
                stepStartMapId = 153093380,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        --map:moveToCell(311)
                        map:door(297)
                    else
                        MoveNext()
                    end
                end
            },
            ["9660"] = {
                displayInfo = "Étape 6 / 10 -- Miner du fer",
                stepStartMapId = 153093380,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        --map:moveToCell(353)
                        map:door(340)
                    else
                        MoveNext()
                    end
                end
            },
            ["9661"] = {
                displayInfo = "Étape 7 / 10 -- Pêcher un poisson",
                stepStartMapId = 153093380,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        --map:moveToCell(330)
                        map:door(303)
                    else
                        MoveNext()
                    end
                end
            },
            ["9662"] = {
                displayInfo = "Étape 8 / 10 -- Fabriquer l'anneau",
                stepStartMapId = 153093380,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        map:useById(508989, -1)
                        craft:putItem(289, 1)
                        craft:putItem(303, 1)
                        craft:putItem(312, 1)
                        craft:putItem(421, 1)
                        craft:putItem(1782, 1)
                        craft:ready()
                        global:leaveDialog()
                    else
                        MoveNext()
                    end
                end
            },
            ["10015"] = {
                displayInfo = "Étape 9 / 10 -- Parler a maître Hoboulo",
                stepStartMapId = 153093380,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        npc:npc(2895 , 3)
                        NpcReply(-1, "slow")
                    else
                        MoveNext()
                    end
                end
            },
            ["9663"] = {
                displayInfo = "Étape 10 / 10 -- Parler a ganymède",
                stepStartMapId = 153092354,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20001)
                        --NpcReply(-1, "slow")
                    else
                        MoveNext()
                    end
                end
            }          
        }
    },
    ["Sous le regard des dieux"] = {
        requiredFinishedQuest = { 1629 },
        questId = 1630,
        stepInfo = {
            ["START"] = {
                displayInfo = "Étape 0 / 6 -- Récupérer la quête",
                stepStartMapId = 153092354,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        24749,
                        24748
                    }
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20001)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end   
            }, 
            ["9680"] = {
                displayInfo = "Etape 1 / 5 -- Entrer dans la salle de combat",
                stepStartMapId = 153092354,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        map:door(189)
                    else
                        MoveNext()
                    end
                end
            },
            ["9685"] = {
                displayInfo = "Etape 2 / 5 -- Parler a Maître Dam",
                stepStartMapId = 153092356,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(-1, 'slow')
                        NpcReply(-1)
                    else
                        MoveNext()
                    end
                end
            },
            ["9720"] = {
                displayInfo = "Etape 3 / 5 -- Combattre les deux monstres",
                stepStartMapId = 153092356,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20002)
                        NpcReply(24793)
                    else
                        MoveNext()
                    end
                end
            },
            ["10121"] = {
                displayInfo = "Etape 3 / 5 -- Combattre les deux monstres",
                stepStartMapId = 153092356,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20001)
                        NpcReply(24791)
                    else
                        MoveNext()
                    end
                end
            },
            ["10016"] = {
                displayInfo = "Etape 4 / 5 -- Parler a Maître Dam",
                stepStartMapId = 153092356,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(-1, "slow")
                    else
                        MoveNext()
                    end
                end
            },
            ["9734"] = {
                displayInfo = "Etape 5 / 5 -- Parler a Ganymède",
                stepStartMapId = 153092354,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(-1)
                        --return EndQuest("npcReply", -1)
                    else
                        MoveNext()
                    end
                end
            }
        }
    },
    ["Réponses à tout"] = {
        questId = 1631,
        requiredFinishedQuest = { 1629, 1630 },
        stepInfo = {
            ["START"] = {
                displayInfo = "Étape 0 / 4 -- Récupérer la quête",
                stepStartMapId = 152043521,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)                       
                        NpcReply(-1, "slow")
                        global:leaveDialog()
                    else
                        MoveNext()
                    end
                end   
            }, 
            ["9730"] = {
                displayInfo = "Étape 1 / 4 -- Lire l'histoire des cra",
                stepStartMapId = 152043521,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        map:door(230)
                        global:leaveDialog()
                    else
                        MoveNext()
                    end
                end
            },
            ["9738"] = {
                displayInfo = "Étape 2 / 4 -- Lire l'histoire des dofus",
                stepStartMapId = 152043521,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        map:door(438)
                        global:leaveDialog()
                    else
                        MoveNext()
                    end
                end
            },
            ["9739"] = {
                displayInfo = "Étape 3 / 4 -- Regarde la carte du monde des douze",
                stepStartMapId = 152043521,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        map:door(362)
                        global:leaveDialog()
                    else
                        MoveNext()
                    end
                end
            },
            ["9740"] = {
                displayInfo = "Étape 4 / 4 -- Parler a Ganymède",
                stepStartMapId = 152043521,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(24801, "slow")
                        NpcReply(24800)
                        NpcReply(24799)
                    else
                        MoveNext()
                    end
                end
            }
        }
    },
    ["Le village dans les nuages"] = {
        questId = 1632,
        stepInfo = {
            ["START"] = {
                displayInfo = "Étape 0 / 7 -- Récupérer la quête",
                stepStartMapId = 154010883,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        24901,
                        24899,
                        24898,
                        24896,
                        24895,
                        24893,
                        24892
                    }

                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end   
            }, 
            ["9762"] = {
                displayInfo = "Étape 1 / 7 -- Allez voir ternette Nhin",
                stepStartMapId = 154010371,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        24919,
                        24927,
                        24290
                    }
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)            
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end
            },
            ["9763"] = {
                displayInfo = "Étape 2 / 7 -- Allez voir Berb Nhin",
                stepStartMapId = 153878787,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        25022,
                        25021,
                        25290
                    }
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end
            },
            ["9764"] = {
                displayInfo = "Étape 3 / 7 -- Allez voir Grobid",
                stepStartMapId = 153357316,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        25029,
                        25028,
                        25023
                    }
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20001)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end
            },
            ["9765"] = {
                displayInfo = "Étape 4 / 7 -- Aller voir Le capitaine des kerubims",
                stepStartMapId = 153356294,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        25044,
                        25043,
                        25038
                    }
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end
            },
            ["9766"] = {
                displayInfo = "Étape 5 / 7 -- Allez voir Hollie Brok",
                stepStartMapId = 153879299,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        25098,
                        25097,
                        25096
                    }
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end
            },
            ["9767"] = {
                displayInfo = "Étape 6 / 7 -- Aller voir Ternette Nhin",
                stepStartMapId = 154010371,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        24930,
                        24929,
                        24928
                    }
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end
            },
            ["9768"] = {
                displayInfo = "Étape 7 / 7 -- Aller voir Fécaline la sage",
                stepStartMapId = 153356296,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        25108,
                        25107,
                        25106
                    }
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end
            }         
        }
    },
    ["Espoirs et tragédies"] = {
        questId = 1634,
        requiredFinishedQuest = { 1632 }, 
        stepInfo = {
            ["START"] = {
                displayInfo = "Étape 0 / 7 -- Récupérer la quête",
                stepStartMapId = 153356296,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        25109,
                        25110
                    }
    
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end   
            }, 
            ["9772"] = {
                displayInfo = "Étape 1 / 7 -- Lire le livre de Rykke Errel",
                stepStartMapId = 153356296,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        map:door(426)
                        global:leaveDialog()
                    else
                        MoveNext()
                    end
                end
            },   
            ["9773"] = {
                displayInfo = "Étape 2 / 7 -- Parler a Fécaline la sage",
                stepStartMapId = 153356296,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        25113,
                        25112,
                        25111
                    }
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end
            },
            ["9774"] = {
                displayInfo = "Étape 3 / 7 -- Parler a un vieux de la vieille",
                stepStartMapId = 154010883,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        24918,
                        24917,
                        24916,
                        24915,
                        24914,
                        24911,
                        24910,
                        24909,
                        24908
                    }
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end
            }, 
            ["9775"] = {
                displayInfo = "Étape 4 / 7 -- Parler a féline pantouflarde",
                stepStartMapId = 153357316,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20002)
                        NpcReply(-1, "slow")
                        NpcReply(-1, "slow")
                        NpcReply(-1, "slow")
                        NpcReply(-1, "slow")
                        NpcReply(-1, "slow")
                        NpcReply(-1, "slow")
                    else
                        MoveNext()
                    end
                end
            }, 
            ["9776"] = {
                displayInfo = "Étape 5 / 7 -- Parler a un voleur malchanceux",
                stepStartMapId = 153879809,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(-1, "slow")
                        NpcReply(-1, "slow")
                        NpcReply(-1, "slow")
                        NpcReply(-1, "slow")
                        NpcReply(-1, "slow")
                    else
                        MoveNext()
                    end
                end
            },
            ["9777"] = {
                displayInfo = "Étape 6 / 6 -- Retourner voir Fécaline la sage",
                stepStartMapId = 153356296,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(25118, "slow")
                        NpcReply(25117, "slow")
                    else
                        MoveNext()
                    end
                end
            }
        }
    },
    ["Dans la gueule du Milimilou"] = {
        questId = 1635,
        minLevel = 15,
        cantStart = true,
        requiredFinishedQuest = { 1634 }, 
        stepInfo = { 
            ["START"] = {
                displayInfo = "Étape 0 / 7 -- Récupérer la quête",
                ["EXECUTE"] = function()
                    local possibleIdReply = {
                        25109,
                        25110
                    }
                    local stepStartMapId = 153356296
    
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end   
            }, 
   
            ["9783"] = {
                displayInfo = "Étape 1 / 7 -- ",
                ["EXECUTE"] = function()
                    local stepStartMapId = 153356296

                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(-1, "slow")
                        NpcReply(-1, "slow")
                        NpcReply(-1, "slow")
                    else
                        MoveNext()
                    end
                end
            }
        }
    }, 
    ["Mise à l'épreuve"] = {
        questId = 1642,
        requiredFinishedQuest = { 1632 },
        stepInfo = { 
            ["START"] = {
                displayInfo = "Étape 0 / 4 -- Récupérer la quête",
                stepStartMapId = 153356294,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(25048, "slow")
                        NpcReply(-1)
                        NpcReply(25045)
                    else
                        MoveNext()
                    end
                end   
            }, 
            ["9828"] = {
                displayInfo = "Étape 1 / 4 -- Allez voir le Caporal Mynerve",
                stepStartMapId = 153356292,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
                    local possibleIdReply = {
                        25091,
                        25089,
                        25088
                    }
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end
            },
            ["9829"] = {
                displayInfo = "Étape 2 / 4 -- Combat contre le Caporal Mynerve",
                stepStartMapId = 153356292,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(-1, "slow")
                        NpcReply(-1)
                    else
                        MoveNext()
                    end
                end
            },
            ["9830"] = {
                displayInfo = "Étape 3 / 4 -- Parler au Capitaine Mynerve",
                stepStartMapId = 153356292,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(-1, "slow")
                        NpcReply(-1, "slow")
                    else
                        MoveNext()
                    end
                end
            },
            ["9831"] = {
                displayInfo = "Étape 4 / 4 -- Parler au Capitaine des kerubims",
                stepStartMapId = 153356294,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(-1, "slow")
                        NpcReply(-1, "slow")
                        NpcReply(-1, "slow")
                        NpcReply(-1, "slow")
                        NpcReply(-1, "slow")
                    else
                        MoveNext()
                    end
                end
            }
        }
    },
    ["Champs de bataille"] = {
        questId = 1643,
        requiredFinishedQuest = { 1642 },
        stepInfo = { 
            ["START"] = {
                displayInfo = "Étape 0 / 5 -- Récupérer la quête",
                stepStartMapId = 153356294,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(-1, "slow")
                        NpcReply(-1)
                        NpcReply(-1)
                    else
                        MoveNext()
                    end
                end   
            }, 
            ["9832"] = {
                displayInfo = "Étape 1 / 5 -- Combattre x1 Tofu chimérique",
                ["EXECUTE"] = function()
                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {
                            { idMonster = 970, min = 1, max = 8 }
                        }
                    }

                    Fight(confMonster)
                    RoadZone(Get_TblZoneSubArea("Incarnam", "Champs"))
                end
            },
            ["9833"] = {
                displayInfo = "Étape 2 / 5 -- Combattre x1 Pissenlit Miroitant",
                ["EXECUTE"] = function()
                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {
                            { idMonster = 979, min = 1, max = 8 }
                        }
                    }

                    Fight(confMonster)
                    RoadZone(Get_TblZoneSubArea("Incarnam", "Champs"))
                end
            },
            ["9834"] = {
                displayInfo = "Étape 3 / 5 -- Combattre x1 Rose Vaporeuse",
                ["EXECUTE"] = function()
                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {
                            { idMonster = 980, min = 1, max = 8 }
                        }
                    }

                    Fight(confMonster)
                    RoadZone(Get_TblZoneSubArea("Incarnam", "Champs"))
                end
            },
            ["9835"] = {
                displayInfo = "Étape 4 / 5 -- Combattre x1 Tournesol Nébuleux",
                ["EXECUTE"] = function()
                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {
                            { idMonster = 981, min = 1, max = 8 }
                        }
                    }

                    Fight(confMonster)                    
                    RoadZone(Get_TblZoneSubArea("Incarnam", "Champs"))
                end
            },
            ["9836"] = {
                displayInfo = "Étape 5 / 5 -- Retourner voir le Capitaine des Kerubims",
                stepStartMapId = 153356294,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(25061, "slow")
                        global:leaveDialog()
                    else
                        MoveNext()
                    end
                end   
            },
        }
    },
    ["Coup d'épée dans l'eau"] = {
        questId = 1644,
        requiredFinishedQuest = { 1643 },
        stepInfo = { 
            ["START"] = {
                displayInfo = "Étape 0 / 4 -- Récupérer la quête",
                stepStartMapId = 153356294,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(25061, "slow")
                        NpcReply(25060)
                    else
                        MoveNext()
                    end
                end   
            }, 
            ["9837"] = {
                displayInfo = "Étape 1 / 4 -- Combattre x2 Petit Gloot",
                ["EXECUTE"] = function()
                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {
                            { idMonster = 4109, min = 1, max = 8 }
                        }
                    }

                    Fight(confMonster)
                    RoadZone(Get_TblZoneSubArea("Incarnam", "Lac"))
                end
            },
            ["9838"] = {
                displayInfo = "Étape 2 / 4 -- Combattre x2 Plikplok",
                ["EXECUTE"] = function()
                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {
                            { idMonster = 4108, min = 1, max = 8 }
                        }
                    }

                    Fight(confMonster)
                    RoadZone(Get_TblZoneSubArea("Incarnam", "Lac"))
                end            
            },
            ["9839"] = {
                displayInfo = "Étape 3 / 4 -- Combattre x1 Grand Splatch",
                ["EXECUTE"] = function()
                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {
                            { idMonster = 4110, min = 1, max = 8 }
                        }
                    }

                    Fight(confMonster)
                    RoadZone(Get_TblZoneSubArea("Incarnam", "Lac"))
                end
            },
            ["9840"] = {
                displayInfo = "Étape 4 / 4 -- Retourner voir le Capitaine des Kerubims",
                stepStartMapId = 153356294,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(25063, "slow")
                        global:leaveDialog()
                    else
                        MoveNext()
                    end
                end   
            }
        }
    },
    ["Décime-moi des bouftous"] = {
        questId = 1645,
        requiredFinishedQuest = { 1644 },
        stepInfo = { 
            ["START"] = {
                displayInfo = "Étape 0 / 5 -- Récupérer la quête",
                stepStartMapId = 153356294,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(25063, "slow")
                        NpcReply(25062)
                    else
                        MoveNext()
                    end
                end   
            }, 
            ["9841"] = {
                displayInfo = "Étape 1 / 5 -- Combattre x1 Boufton Pâlichon",
                ["EXECUTE"] = function()
                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {
                            { idMonster = 972, min = 1, max = 8 }
                        }
                    }

                    Fight(confMonster)
                    RoadZone(Get_TblZoneSubArea("Incarnam", "Pâturages"))
                end
            },
            ["9842"] = {
                displayInfo = "Étape 2 / 5 -- Combattre x1 Boufton Orageux",
                ["EXECUTE"] = function()
                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {
                            { idMonster = 973, min = 1, max = 8 }
                        }
                    }

                    Fight(confMonster)
                    RoadZone(Get_TblZoneSubArea("Incarnam", "Pâturages"))
                end            
            },
            ["9843"] = {
                displayInfo = "Étape 3 / 5 -- Combattre x1 Bouftou Nuageux",
                ["EXECUTE"] = function()
                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {
                            { idMonster = 971, min = 1, max = 8 }
                        }
                    }

                    Fight(confMonster)
                    RoadZone(Get_TblZoneSubArea("Incarnam", "Pâturages"))
                end
            },
            ["9844"] = {
                displayInfo = "Étape 3 / 5 -- Combattre x1 Bouftor Éthéré",
                ["EXECUTE"] = function()
                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {
                            { idMonster = 984, min = 1, max = 8 }
                        }
                    }

                    Fight(confMonster)
                    RoadZone(Get_TblZoneSubArea("Incarnam", "Pâturages"))
                end
            },  
            ["9845"] = {
                displayInfo = "Étape 5 / 5 -- Retourner voir le Capitaine des Kerubims",
                stepStartMapId = 153356294,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(25065, "slow")
                    else
                        MoveNext()
                    end
                end   
            }      
        }
    },
    ["Chasse aux chapardams"] = {
        questId = 1646,
        requiredFinishedQuest = { 1645 },
        stepInfo = { 
            ["START"] = {
                displayInfo = "Étape 0 / 4 -- Récupérer la quête",
                stepStartMapId = 153356294,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(25065, "slow")
                        NpcReply(25064)
                    else
                        MoveNext()
                    end
                end   
            }, 
            ["9846"] = {
                displayInfo = "Étape 1 / 4 -- Combattre x2 Ronronchon",
                ["EXECUTE"] = function()
                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {
                            { idMonster = 4105, min = 1, max = 8 }
                        }
                    }

                    Fight(confMonster)
                    RoadZone(Get_TblZoneSubArea("Incarnam", "Forêt"))
                end
            },
            ["9847"] = {
                displayInfo = "Étape 2 / 4 -- Combattre x2 Tigrimas",
                ["EXECUTE"] = function()
                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {
                            { idMonster = 4106, min = 1, max = 8 }
                        }
                    }

                    Fight(confMonster)
                    RoadZone(Get_TblZoneSubArea("Incarnam", "Forêt"))
                end            
            },
            ["9848"] = {
                displayInfo = "Étape 3 / 4 -- Combattre x2 Chakrobat",
                ["EXECUTE"] = function()
                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {
                            { idMonster = 982, min = 1, max = 8 }
                        }
                    }

                    Fight(confMonster)
                    RoadZone(Get_TblZoneSubArea("Incarnam", "Forêt"))
                end
            },
            ["9849"] = {
                displayInfo = "Étape 4 / 4 -- Retourner voir le Capitaine des Kerubims",
                stepStartMapId = 153356294,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(-1, "slow")
                    else
                        MoveNext()
                    end
                end   
            }      
        }
    },
    ["Leçon d'humilité"] = {
        questId = 1647,
        requiredFinishedQuest = { 1646 },
        stepInfo = { 
            ["START"] = {
                displayInfo = "Étape 0 / 2 -- Récupérer la quête",
                stepStartMapId = 153356294,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(25067, "slow")
                        NpcReply(25066)
                    else
                        MoveNext()
                    end
                end   
            }, 
            ["9850"] = {
                displayInfo = "Étape 1 / 2 -- Combattre Kruella Freuz",
                stepStartMapId = 153879040,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(25082, "slow")
                    else
                        MoveNext()
                    end
                end
            },
            ["9851"] = {
                displayInfo = "Étape 2 / 2 -- Retourner voir le Capitaine des Kerubims",
                stepStartMapId = 153356294,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(25071, "slow")
                    else
                        MoveNext()
                    end
                end            
            }
        }
    },
    ["Des chafers qui marchent"] = {
        questId = 1648,
        requiredFinishedQuest = { 1647 },
        stepInfo = { 
            ["START"] = {
                displayInfo = "Étape 0 / 8 -- Récupérer la quête",
                stepStartMapId = 153356294,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        25071,
                        25070,
                        25069,
                        25068
                    }
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end   
            }, 
            ["9852"] = {
                displayInfo = "Étape 1 / 8 -- Combattre x1 Chafer débutant",
                ["EXECUTE"] = function()
                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {
                            { idMonster = 4046, min = 1, max = 8 }
                        }
                    }

                    Fight(confMonster)
                    RoadZone(Get_TblZoneSubArea("Incarnam", "Cimetière"))
                end
            },
            ["9853"] = {
                displayInfo = "Étape 2 / 8 -- Combattre x1 Chafer furtif",
                ["EXECUTE"] = function()
                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {
                            { idMonster = 4047, min = 1, max = 8 }
                        }
                    }

                    Fight(confMonster)
                    RoadZone(Get_TblZoneSubArea("Incarnam", "Cimetière"))
                end
            },  
            ["9854"] = {
                displayInfo = "Étape 3 / 8 -- Combattre x1 Chafer éclaireur",
                ["EXECUTE"] = function()
                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 2,
                        conf = {
                            { idMonster = 4048, min = 1, max = 8 }
                        }
                    }

                    Fight(confMonster)
                    RoadZone(Get_TblZoneSubArea("Incarnam", "Cimetière"))
                end
            }, 
            ["9855"] = {
                displayInfo = "Étape 4 / 8 -- Combattre x1 Chafer Piquier",
                ["EXECUTE"] = function()
                    local confMonster = {
                        minMonster = 1,
                        maxMonster = 3,
                        conf = {
                            { idMonster = 4049, min = 1, max = 8 }
                        }
                    }

                    Fight(confMonster)
                    RoadZone(Get_TblZoneSubArea("Incarnam", "Cimetière"))
                end
            }, 
            ["9856"] = {
                displayInfo = "Étape 5 / 8 -- Découvrir la carte : Tombeau de Percy Klop",
                stepStartMapId = 153881090,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then
                        map:door(361)                        
                    else
                        MoveNext()
                    end
                end
            }, 
            ["9859"] = {
                displayInfo = "Étape 6 / 8 -- Fouiller la tombe",
                stepStartMapId = 153356288,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then
                        map:door(343)                        
                    else
                        MoveNext()
                    end
                end
            },   
            ["9857"] = {
                displayInfo = "Étape 7 / 8 -- Combattre x1 Percy Klop",
                stepStartMapId = 153356288,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then
                        NpcDialogRequest(-20000)
                        NpcReply(25086)
                    else
                        MoveNext()
                    end
                end
            },
            ["9858"] = {
                displayInfo = "Étape 8 / 8 -- Retourner voir le Capitaine des Kerubims",
                stepStartMapId = 153356294,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then
                        NpcDialogRequest(-20000)
                        NpcReply(25073)
                    else
                        MoveNext()
                    end
                end
            }
        }
    },
    ["Transport peu commun"] = {
        questId = 1639,
        stepInfo = { 
            ["START"] = {
                displayInfo = "Étape 0 / 3 -- Récupérer la quête",
                stepStartMapId = 154010371,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        24936,
                        24935,
                        24934,
                        24933,
                        24932,
                        24931
                    }

                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end   
            }, 
            ["9814"] = {
                displayInfo = "Étape 1 / 3 -- Allez voir Xélora Fistol",
                stepStartMapId = 153879813,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(25020, "slow")
                        NpcReply(25019)
                        NpcReply(25018)
                        NpcReply(25017)
                        NpcReply(25016)
                    else
                        MoveNext()
                    end
                end
            },
            ["9815"] = {
                displayInfo = "Étape 2 / 3 -- Examiner le zaap des pâturages",
                stepStartMapId = 153879813,
                ["EXECUTE"] = function(stepStartMapId)    
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        map:useById(509249, -1) 
                    else
                        MoveNext()
                    end                
                end
            },
            ["9816"] = {
                displayInfo = "Étape 3 / 3 -- Retourner voir Ternette Nhin",
                stepStartMapId = 154010371,
                ["EXECUTE"] = function(stepStartMapId)    
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(24940, "slow")
                        global:leaveDialog()
                    else
                        MoveNext()
                    end                
                end
            }
        }
    }, 
    ["Des vestiges de légende"] = {
        questId = 1640,
        requiredFinishedQuest = { 1639 },
        stepInfo = { 
            ["START"] = {
                displayInfo = "Étape 0 / 3 -- Récupérer la quête",
                stepStartMapId = 154010371,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        24943,
                        24942,
                        24941
                    }

                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end   
            }, 
            ["9817"] = {
                displayInfo = "Étape 1 / 6 -- Examiner la stèle d'un vestige sur la route des âmes",
                stepStartMapId = 153878787,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        map:door(485)
                        global:leaveDialog()
                    else
                        MoveNext()
                    end
                end
            },
            ["9818"] = {
                displayInfo = "Étape 2 / 6 -- Examiner la stèle d'un vestige des champs",
                stepStartMapId = 154010886,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        map:door(332)
                        global:leaveDialog()                        
                    else
                        MoveNext()
                    end                
                end
            },
            ["9819"] = {
                displayInfo = "Étape 3 / 6 -- Examiner la stèle d'un vestige près du lac",
                stepStartMapId = 154010882,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        map:door(471)
                        global:leaveDialog()                        
                    else
                        MoveNext()
                    end                
                end
            },
            ["9820"] = {
                displayInfo = "Étape 4 / 6 -- Examiner la stèle d'un vestige dans les pâturages",
                stepStartMapId = 153879301,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        map:door(344)
                        global:leaveDialog()                        
                    else
                        MoveNext()
                    end                
                end
            },
            ["9821"] = {
                displayInfo = "Étape 5 / 6 -- Examiner la stèle d'un vestige dans la forêt",
                stepStartMapId = 153879297,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        map:door(415)
                        global:leaveDialog()                        
                    else
                        MoveNext()
                    end                
                end
            },
            ["9822"] = {
                displayInfo = "Étape 6 / 6 -- Retourner voir Ternette N'hin",
                stepStartMapId = 154010371,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(24947, "slow")
                    else
                        MoveNext()
                    end
                end
            }
        }
    }, 
    ["Vu du ciel"] = {
        questId = 1641,
        requiredFinishedQuest = { 1640 },
        stepInfo = { 
            ["START"] = {
                displayInfo = "Étape 0 / 5 -- Récupérer la quête",
                stepStartMapId = 154010371,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        24950,
                        24949,
                        24948
                    }

                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end   
            }, 
            ["9823"] = {
                displayInfo = "Étape 1 / 5 -- Allez voir Matu Vuh",
                stepStartMapId = 154010374,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(24957, "slow")
                        NpcReply(24956)
                    else
                        MoveNext()
                    end
                end
            },
            ["9824"] = {
                displayInfo = "Étape 2 / 5 -- Utiliser la longue vue de Matu Vuh",
                stepStartMapId = 154010374,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        map:useById(489417, -1)
                        global:leaveDialog()                   
                    else
                        MoveNext()
                    end
                end
            },
            ["9825"] = {
                displayInfo = "Étape 3 / 5 -- Allez voir galilea",
                stepStartMapId = 154010113,
                ["EXECUTE"] = function(stepStartMapId)    
                    LoadRoadIfNotInMap(stepStartMapId)
  
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(24963)
                        NpcReply(24962)
                    elseif map:currentMapId() == 154010369 then
                        map:changeMap("left") 
                    elseif map:currentMapId() == 154010881 then
                        map:changeMap("bottom")                   
                 
                    else
                        map:moveToward(154010113)
                    end                
                end
            },
            ["9826"] = {
                displayInfo = "Étape 4 / 5 -- Utiliser la longue vue de Galilea",
                stepStartMapId = 154010113,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        map:useById(489418, -1)
                        global:leaveDialog()                   
                    else
                        MoveNext()
                    end
                end
            }, 
            ["9827"] = {
                displayInfo = "Étape 5 / 5 -- Retourner voir Ternette Nhin",
                stepStartMapId = 154010371,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(24952)
                    else
                        MoveNext()
                    end
                end
            }
        }
    },
    ["Produits naturels"] = {
        questId = 1649,
        stepInfo = { 
            ["START"] = {
                displayInfo = "Étape 0 / 5 -- Récupérer la quête",
                stepStartMapId = 153878787,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        25298,
                        25306,
                        25304,
                        25303,
                        25302,
                        25301
                    }

                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end   
            }, 
            ["9863"] = {
                displayInfo = "Étape 1 / 5 -- Fabriquer x1 Pain d'Incarnam",
                stepStartMapId = 153354242,
                ["EXECUTE"] = function(stepStartMapId)
                    if inventory:itemCount(289) < 4 then
                        GATHER = {38}

                        Gather()
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Champs"))
                    else
                        LoadRoadIfNotInMap(stepStartMapId)
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(489524, -1)
                            craft:putItem(289, 4)
                            craft:ready()
                            global:leaveDialog()
                        else
                            MoveNext()
                        end    
                    end

                end
            },
            ["9864"] = {
                displayInfo = "Étape 2 / 5 -- Fabriquer x1 Goujon en tranche",
                stepStartMapId = 153354246,
                ["EXECUTE"] = function(stepStartMapId)
                    if inventory:itemCount(1782) < 4 then
                        GATHER = {75}
                        Gather()
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Lac"))
                    else
                        LoadRoadIfNotInMap(stepStartMapId)
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(489364, -1)
                            craft:putItem(1782, 4)
                            craft:ready()
                            global:leaveDialog()
                        else
                            MoveNext()
                        end    
                    end
                end
            },
            ["9866"] = {
                displayInfo = "Étape 3 / 5 -- Fabriquer x1 Potion de mini soin",
                stepStartMapId = 153355270,
                ["EXECUTE"] = function(stepStartMapId)
                    if inventory:itemCount(421) < 4 then
                        GATHER = {254}
                        Gather()
                        RoadZone(Get_TblZoneSubArea("Incarnam", {"Forêt", "Lac", "Pâturages", "Route des âmes", "Champs"}))
                    else
                        LoadRoadIfNotInMap(stepStartMapId)
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(489066, -1)
                            craft:putItem(421, 4)
                            craft:ready()
                            global:leaveDialog()
                        else
                            MoveNext()
                        end    
                    end
                end
            },
            ["FINISH"] = {
                displayInfo = "Étape 4 / 4 -- Retourner voir Berb N'hin",
                stepStartMapId = 153878787,
                ["EXECUTE"] = function(stepStartMapId)

                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(25311)
                    else
                        MoveNext()
                    end    
                end
            }
        }
    }, 
    ["La hache et la pioche"] = {
        questId = 1650,
        requiredFinishedQuest = { 1649 },
        stepInfo = { 
            ["START"] = {
                displayInfo = "Étape 0 / 5 -- Récupérer la quête",
                stepStartMapId = 153878787,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        25312,
                        25314,
                        25313,
                    }

                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end   
            }, 
            ["9871"] = {
                displayInfo = "Étape 1 / 5 -- Fabriquer x1 Planche Agglomérée",
                stepStartMapId = 153355266,
                ["EXECUTE"] = function(stepStartMapId)
                    local pathFrene = {
                        153879298,
                        153879297,
                        153879040,
                        153879552,
                        153879809,
                        153879810,
                        153880322,
                        153880321
                    }

                    local pathMine = {
                        153358338,
                        153358336,
                        153357314,
                        153357312
                    }

                    if inventory:itemCount(303) < 6 then -- Frêne
                        GATHER = {1}

                        Gather()
                        RoadZone(pathFrene)
                    elseif inventory:itemCount(312) < 4 then -- Fer
                        GATHER = {17}

                        Gather()
                        RoadZone(pathMine)
                    else
                        LoadRoadIfNotInMap(stepStartMapId)
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(489534, -1)
                            craft:putItem(303, 6)
                            craft:putItem(312, 4)
                            craft:ready()
                            global:leaveDialog()
                        else
                            MoveNext()
                        end    
                    end

                end
            },
            ["9872"] = {
                displayInfo = "Étape 2 / 5 -- Fabriquer x1 Ferrite",
                stepStartMapId = 153355264,
                ["EXECUTE"] = function(stepStartMapId)
                    local pathFrene = {
                        153879298,
                        153879297,
                        153879040,
                        153879552,
                        153879809,
                        153879810,
                        153880322,
                        153880321
                    }

                    local pathMine = {
                        153358338,
                        153358336,
                        153357314,
                        153357312
                    }

                    if inventory:itemCount(303) < 10 then -- Frêne
                        GATHER = {1}

                        Gather()
                        RoadZone(pathFrene)
                    elseif inventory:itemCount(312) < 6 then -- Fer
                        GATHER = {17}

                        Gather()
                        RoadZone(pathMine)
                    else
                        LoadRoadIfNotInMap(stepStartMapId)
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(489176, -1)
                            craft:putItem(303, 10)
                            craft:putItem(312, 6)
                            craft:ready()
                            global:leaveDialog()
                        else
                            MoveNext()
                        end    
                    end                
                end
            },
            ["9866"] = {
                displayInfo = "Étape 3 / 5 -- Fabriquer x1 Potion de mini soin",
                stepStartMapId = 153355270,
                ["EXECUTE"] = function(stepStartMapId)
                    local tblMapId = {
                        153879298,
                        153879297,
                        153879040,
                        153879552,
                        153879809,
                        153879810,
                        153880322,
                        153880321
                    }

                    if inventory:itemCount(421) < 4 then
                        GATHER = {254}
                        Gather()
                        RoadZone(tblMapId)
                    else
                        LoadRoadIfNotInMap(stepStartMapId)
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(489066, -1)
                            craft:putItem(421, 4)
                            craft:ready()
                            global:leaveDialog()
                        else
                            MoveNext()
                        end    
                    end
                end
            },
            ["FINISH"] = {
                displayInfo = "Étape 4 / 4 -- Retourner voir Berb N'hin",
                stepStartMapId = 153878787,
                ["EXECUTE"] = function(stepStartMapId)

                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(25320)
                    else
                        MoveNext()
                    end    
                end
            }
        }
    },
    ["Boune un jour, boune toujours"] = {
        questId = 1651,
        requiredFinishedQuest = { 1650 },
        stepInfo = { 
            ["START"] = {
                displayInfo = "Étape 0 / 7 -- Récupérer la quête",
                stepStartMapId = 153878787,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        25322,
                        25326,
                        25325,
                        25324,
                        25323
                    }

                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end   
            }, 
            ["9875"] = {
                displayInfo = "Étape 1 / 7 -- Fabriquer x1 Le S'Mesme",
                stepStartMapId = 153355272,
                ["EXECUTE"] = function(stepStartMapId)
                    if inventory:itemCount(16512) < 2 then -- Plume chimérique
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {
                                { idMonster = 970, min = 1, max = 8 }
                            }
                        }
    
                        Fight(confMonster)
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Champs"))
                    elseif inventory:itemCount(303) < 2 then -- Frêne
                        GATHER = {1}

                        Gather()
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Forêt"))
                    else
                        LoadRoadIfNotInMap(stepStartMapId)
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(489550, -1)
                            craft:putItem(16512, 2)
                            craft:putItem(303, 2)
                            craft:ready()
                            global:leaveDialog()
                        else
                            MoveNext()
                        end    
                    end

                end
            },
            ["9877"] = {
                displayInfo = "Étape 2 / 7 -- Fabriquer x1 Le Plussain",
                stepStartMapId = 153355272,
                ["EXECUTE"] = function(stepStartMapId)
                    if inventory:itemCount(16518) < 2 then -- Feu Intérieur
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 4,
                            conf = {}
                        } 

                        if InMapChecker(Get_TblZoneSubArea("Incarnam", "Route des âmes")) then
                            Fight(confMonster)
                        end                        
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Route des âmes"))                    
                    elseif inventory:itemCount(312) < 1 then -- Fer
                        GATHER = {17}

                        Gather()
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Mine"))
                    else
                        LoadRoadIfNotInMap(stepStartMapId)
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(489550, -1)
                            craft:putItem(16518, 2)
                            craft:putItem(312, 1)
                            craft:ready()
                            global:leaveDialog()
                        else
                            MoveNext()
                        end    
                    end                
                end
            },
            ["9878"] = {
                displayInfo = "Étape 3 / 7 -- Fabriquer x1 Les Incrustes",
                stepStartMapId = 153354244,
                ["EXECUTE"] = function(stepStartMapId)
                    if inventory:itemCount(16513) < 2 then -- Pétale Diaphane
                        local tblMapId = Get_TblZoneSubArea("Incarnam", "Champs")
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 4,
                            conf = {
                                { idMonster = 970, min = 0, max = 0 }
                            }                        
                        } 

                        if InMapChecker(tblMapId) then
                            Fight(confMonster)
                        end                        
                        RoadZone(tblMapId)                    
                    elseif inventory:itemCount(303) < 2 then -- Frêne
                        GATHER = {1}

                        Gather()
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Forêt"))
                    else
                        LoadRoadIfNotInMap(stepStartMapId)
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(489570, -1)
                            craft:putItem(16513, 2)
                            craft:putItem(303, 2)
                            craft:ready()
                            global:leaveDialog()
                        else
                            MoveNext()
                        end    
                    end                 
                end
            },
            ["9879"] = {
                displayInfo = "Étape 4 / 7 -- Fabriquer x1 La Spamette",
                stepStartMapId = 153354244,
                ["EXECUTE"] = function(stepStartMapId)
                    if inventory:itemCount(16522) < 2 then -- Peau de gloot
                        local tblMapId = Get_TblZoneSubArea("Incarnam", "Lac")
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 4,
                            conf = {}                        
                        } 

                        if InMapChecker(tblMapId) then
                            Fight(confMonster)
                        end                        
                        RoadZone(tblMapId)                    
                    elseif inventory:itemCount(421) < 2 then -- Ortie
                        GATHER = {254}

                        Gather()
                        RoadZone(Get_TblZoneSubArea("Incarnam", {"Forêt", "Lac", "Pâturages", "Route des âmes", "Champs"}))
                    else
                        LoadRoadIfNotInMap(stepStartMapId)
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(489570, -1)
                            craft:putItem(16522, 2)
                            craft:putItem(421, 2)
                            craft:ready()
                            global:leaveDialog()
                        else
                            MoveNext()
                        end    
                    end                 
                end
            },
            ["9880"] = {
                displayInfo = "Étape 5 / 7 -- Fabriquer x1 La Cape S'loque",
                stepStartMapId = 153354244,
                ["EXECUTE"] = function(stepStartMapId)

                    if inventory:itemCount(1984) < 2 then -- Cendres éternelles
                        local tblMapId = Get_TblZoneSubArea("Incarnam", "Route des âmes")
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 4,
                            conf = {}                        
                        } 

                        if InMapChecker(tblMapId) then
                            Fight(confMonster)
                        end                        
                        RoadZone(tblMapId)                    
                    elseif inventory:itemCount(312) < 1 then -- Fer
                        GATHER = {17}

                        Gather()
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Mine"))
                    else
                        LoadRoadIfNotInMap(stepStartMapId)
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(489571, -1)
                            craft:putItem(1984, 2)
                            craft:putItem(312, 1)
                            craft:ready()
                            global:leaveDialog()
                        else
                            MoveNext()
                        end    
                    end                
                end
            },
            ["9881"] = {
                displayInfo = "Étape 6 / 7 -- Fabriquer x1 Le Floude",
                stepStartMapId = 153354244,
                ["EXECUTE"] = function(stepStartMapId)

                    if inventory:itemCount(16511) < 2 then -- Laine céleste
                        local tblMapId = Get_TblZoneSubArea("Incarnam", "Pâturages")
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 4,
                            conf = {}                        
                        } 

                        if InMapChecker(tblMapId) then
                            Fight(confMonster)
                        end                        
                        RoadZone(tblMapId)                    
                    elseif inventory:itemCount(421) < 2 then -- Ortie
                        GATHER = {254}

                        Gather()
                        RoadZone(Get_TblZoneSubArea("Incarnam", {"Forêt", "Lac", "Pâturages", "Route des âmes", "Champs"}))
                    else
                        LoadRoadIfNotInMap(stepStartMapId)
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(489571, -1)
                            craft:putItem(16511, 2)
                            craft:putItem(421, 2)
                            craft:ready()
                            global:leaveDialog()
                        else
                            MoveNext()
                        end    
                    end                  
                end
            },
            ["FINISH"] = {
                displayInfo = "Étape 7 / 7 -- Retourner voir Berb N'hin",
                stepStartMapId = 153878787,
                ["EXECUTE"] = function(stepStartMapId)

                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(25330)
                    else
                        MoveNext()
                    end    
                end
            }
        }
    }, 
    ["Le choix des armes"] = {
        questId = 1652,
        requiredFinishedQuest = { 1651 },
        stepInfo = { 
            ["START"] = {
                displayInfo = "Étape 0 / 4 -- Récupérer la quête",
                stepStartMapId = 153878787,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        25333,
                        25336,
                        25335,
                        25334
                    }

                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end   
            }, 
            ["9888"] = {
                displayInfo = "Étape 1 / 4 -- Fabriquer x1 Demi-Baguette",
                stepStartMapId = 153355266,
                ["EXECUTE"] = function(stepStartMapId)
                    if inventory:itemCount(16513) < 3 then -- Pétale Diaphane
                        local tblMapId = Get_TblZoneSubArea("Incarnam", "Champs")
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 4,
                            conf = {
                                { idMonster = 970, min = 0, max = 0 }
                            }                        
                        } 

                        if InMapChecker(tblMapId) then
                            Fight(confMonster)
                        end                        
                        RoadZone(tblMapId)                    
                    elseif inventory:itemCount(16511) < 3 then -- Laine céleste
                        local tblMapId = Get_TblZoneSubArea("Incarnam", "Pâturages")
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 4,
                            conf = {}                        
                        } 

                        if InMapChecker(tblMapId) then
                            Fight(confMonster)
                        end                        
                        RoadZone(tblMapId)                    
                    else
                        LoadRoadIfNotInMap(stepStartMapId)
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(489533, -1)
                            craft:putItem(16513, 3)
                            craft:putItem(16511, 3)
                            craft:ready()
                            global:leaveDialog()
                        else
                            MoveNext()
                        end    
                    end
                end
            },
            ["9889"] = {
                displayInfo = "Étape 2 / 4 -- Fabriquer x1 Hachette de bûcheron",
                stepStartMapId = 153355264,
                ["EXECUTE"] = function(stepStartMapId)
                    if inventory:itemCount(16511) < 5 then -- Laine céleste
                        local tblMapId = Get_TblZoneSubArea("Incarnam", "Pâturages")
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 4,
                            conf = {}                        
                        } 

                        if InMapChecker(tblMapId) then
                            Fight(confMonster)
                        end                        
                        RoadZone(tblMapId)                    
                    elseif inventory:itemCount(312) < 1 then -- Fer
                        GATHER = {17}

                        Gather()
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Mine"))
                    else
                        LoadRoadIfNotInMap(stepStartMapId)
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(489177, -1)
                            craft:putItem(16511, 5)
                            craft:putItem(312, 1)
                            craft:ready()
                            global:leaveDialog()
                        else
                            MoveNext()
                        end    
                    end                  
                end
            },
            ["9890"] = {
                displayInfo = "Étape 3 / 4 -- Fabriquer x1 Clef de la crypte de kardorim",
                stepStartMapId = 153354248,
                ["EXECUTE"] = function(stepStartMapId)
                    if inventory:itemCount(16524) < 3 then -- Relique d'incarnam
                        local tblMapId = Get_TblZoneSubArea("Incarnam", "Cimetière")
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 4,
                            conf = {}                        
                        } 

                        if InMapChecker(tblMapId) then
                            Fight(confMonster)
                        end                        
                        RoadZone(tblMapId)                    
                    elseif inventory:itemCount(1984) < 5 then -- Cendre éternelles
                        local tblMapId = Get_TblZoneSubArea("Incarnam", "Route des âmes")
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 4,
                            conf = {}                        
                        } 

                        if InMapChecker(tblMapId) then
                            Fight(confMonster)
                        end                        
                        RoadZone(tblMapId)                    
                    else
                        LoadRoadIfNotInMap(stepStartMapId)
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(490183, -1)
                            craft:putItem(16524, 3)
                            craft:putItem(1984, 5)
                            craft:ready()
                            global:leaveDialog()
                        else
                            MoveNext()
                        end    
                    end
                end
            },
            ["FINISH"] = {
                displayInfo = "Étape 4 / 4 -- Retourner voir Berb N'hin",
                stepStartMapId = 153878787,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(25337)
                        NpcReply(25341)
                    else
                        MoveNext()
                    end    
                end
            }
        }
    },
    ["La galette secrète"] = {
        questId = 1637,
        stepInfo = { 
            ["START"] = {
                displayInfo = "Étape 0 / 5 -- Récupérer la quête",
                stepStartMapId = 153879298,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        25216,
                        25214,
                        25213,
                        25212
                    }

                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end
                end   
            }, 
            ["9805"] = {
                displayInfo = "Étape 1 / 5 -- Lire la recette de la galette d'Incarnam",
                ["EXECUTE"] = function()
                    inventory:useItem(16517)
                    global:leaveDialog()
                end
            },
            ["9806"] = {
                displayInfo = "Étape 2 / 5 -- Fabriquer x1 Galette d'Incarnam",
                stepStartMapId = 153354242,
                ["EXECUTE"] = function(stepStartMapId)
                    if inventory:itemCount(289) < 10 then -- Blé
                        GATHER = {38}

                        Gather()
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Champs"))

                    elseif inventory:itemCount(519) < 4 then -- Poudre de perlinpainpain
                        local tblMapId = Get_TblZoneSubArea("Incarnam", "Champs")
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 4,
                            conf = {}                        
                        } 

                        if InMapChecker(tblMapId) then
                            Fight(confMonster)
                        end                        
                        RoadZone(tblMapId)

                    elseif inventory:itemCount(367) < 2 then -- Oeufs de tofu
                        local tblMapId = Get_TblZoneSubArea("Incarnam", "Champs")
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 4,
                            conf = {
                                { idMonster = 970, min = 1, max = 8 }
                            }                        
                        } 

                        if InMapChecker(tblMapId) then
                            Fight(confMonster)
                        end                        
                        RoadZone(tblMapId)
                    elseif inventory:itemCount(6765) < 1 then -- LaitLait
                        LoadRoadIfNotInMap(153357316)

                        if map:currentMapId() == 153357316 then
                            NpcDialogRequest(-20001)
                            NpcReply(25036)
                            NpcReply(25035)
                        else
                            MoveNext()
                        end
                    elseif inventory:itemCount(1984) < 4 then -- Cendres éternelles
                        local tblMapId = Get_TblZoneSubArea("Incarnam", "Route des âmes")
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 4,
                            conf = {}                        
                        } 

                        if InMapChecker(tblMapId) then
                            Fight(confMonster)
                        end                        
                        RoadZone(tblMapId)
                    elseif inventory:itemCount(385) < 4 then -- Bave de bouftout
                        local tblMapId = Get_TblZoneSubArea("Incarnam", "Paturâges")
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 4,
                            conf = {}                        
                        } 

                        if InMapChecker(tblMapId) then
                            Fight(confMonster)
                        end                        
                        RoadZone(tblMapId)

                    else
                        LoadRoadIfNotInMap(stepStartMapId)
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(489524, -1)
                            craft:putItem(289, 10)
                            craft:putItem(519, 4)
                            craft:putItem(367, 2)
                            craft:putItem(6765, 1)
                            craft:putItem(1984, 4)
                            craft:putItem(385, 4)
                            craft:ready()
                            global:leaveDialog()
                        else
                            MoveNext()
                        end    
                    end                  
                end
            },
            ["9807"] = {
                displayInfo = "Étape 3 / 5 -- Retourner voir AntaBrok",
                stepStartMapId = 153879298,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(25218)
                        NpcReply(25217)
                    else
                        MoveNext()
                    end    
                end
            },
            ["9808"] = {
                displayInfo = "Étape 4 / 5 -- Allez voir Pipelette",
                stepStartMapId = 153879811,
                ["EXECUTE"] = function(stepStartMapId)
                    if inventory:itemCount(421) < 5 then -- Ortie
                        GATHER = {254}

                        Gather()
                        RoadZone(Get_TblZoneSubArea("Incarnam", {"Forêt", "Lac", "Pâturages", "Route des âmes", "Champs"}))
                    else
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20002)
                            NpcReply(25229)
                            NpcReply(25228)
                            NpcReply(25227)
                            NpcReply(25226)
                        else
                            MoveNext()
                        end 
                    end   
                end
            },
            ["FINISH"] = {
                displayInfo = "Étape 5 / 5 -- Montrer à Anta Brok 1 Pot de confiture Maison",
                stepStartMapId = 153879298,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        25224,
                        25221,
                        25220,
                        25219
                    }

                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end    
                end
            },
        }
    },
    ["Mort au rat !"] = {
        questId = 1633,
        stepInfo = { 
            ["START"] = {
                displayInfo = "Étape 0 / 4 -- Récupérer la quête",
                stepStartMapId = 153878787,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        map:useById(489412, -1)
                        PacketSender("QuestStartRequestMessage", function(msg)
                            msg.questId = 1633
                            return msg
                        end)
                    else
                        MoveNext()
                    end
                end   
            }, 
            ["9895"] = {
                displayInfo = "Étape 1 / 4 -- Inspecter la cave",
                stepStartMapId = 153358340,
                ["EXECUTE"] = function()
                    LoadRoadIfNotInMap(stepStartMapId)
    
                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        map:useById(489505, -1)                     
                    else
                        MoveNext()
                    end                
                end
            },
            ["9769"] = {
                displayInfo = "Étape 2 / 4 -- Faire sortir le rat de sa cachette",
                stepStartMapId = 153358340,
                ["EXECUTE"] = function(stepStartMapId)
                    if inventory:itemCount(8543) < 1 then -- Limonade d'incarnam
                        LoadRoadIfNotInMap(153357316)

                        if map:currentMapId() == 153357316 then
                            NpcDialogRequest(-20001)
                            NpcReply(25036)
                            NpcReply(25034)
                        else
                            MoveNext()
                        end

                    else
                        LoadRoadIfNotInMap(stepStartMapId)
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(489505, -1)                     
                        else
                            MoveNext()
                        end    
                    end                  
                end
            },
            ["9770"] = {
                displayInfo = "Étape 3 / 4 -- Vaincre x1 Rat Soiffé",
                stepStartMapId = 153358340,
                ["EXECUTE"] = function(stepStartMapId)
                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20000)
                        NpcReply(25037)
                    else
                        MoveNext()
                    end    
                end
            },
            ["FINISH"] = {
                displayInfo = "Étape 4 / 4 -- Allez voir Grobid",
                stepStartMapId = 153357316,
                ["EXECUTE"] = function(stepStartMapId)
                    local possibleIdReply = {
                        25033,
                        25032
                    }

                    LoadRoadIfNotInMap(stepStartMapId)

                    if map:currentMapId() == stepStartMapId then -- Execution étape
                        NpcDialogRequest(-20001)
                        ReplyUntilLeave(possibleIdReply)
                    else
                        MoveNext()
                    end    
                end
            },
        }
    },
}

local ZONE_AREA_MAPID = {
    ["Incarnam"] = {
        ["Route des âmes"] = {
            154010883,
            154010371,
            153878787,
            153879299,
            153879811,
            153880323,
            153880835
        },
        ["Pâturages"] = {
            153879301,
            153879813,
            153880325,
            153880836,
            153880324,
            153879812,
            153879300
        },
        ["Champs"] = {
            153878788,
            154010372,
            154010884,
            154010885,
            154011397,
            154011398,
            154010886,
            154010374,
            154010373
        },
        ["Lac"] = {
            153878786,
            153878785,
            153878528,
            153878529,
            154010113,
            154010112,
            154010624,
            154010881,
            154010369,
            154010882,
            154010370
        },
        ["Forêt"] = {
            153879298,
            153879297,
            153879040,
            153879552,
            153879809,
            153879810,
            153880322,
            153880321
        },
        ["Cimetière"] = {
            153881090,
            153880578,
            153881089,
            153881601,
            153881600,
            153881088
        },
        ["Mine"] = {
            153358338,
            153358336,
            153357314,
            153357312
        }
    }
}

return QUEST, ZONE_AREA_MAPID