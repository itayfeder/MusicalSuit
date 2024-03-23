--- STEAMODDED HEADER
--- MOD_NAME: Musical Suit
--- MOD_ID: MusicalSuit
--- MOD_AUTHOR: [itayfeder]
--- MOD_DESCRIPTION: This mod add Notes suit.

----------------------------------------------
------------MOD CODE -------------------------

local NOTE_SUIT_SYMBOL = nil
local NOTE_SUIT_INDEX = nil
local NOTE_SUIT_VALUE = nil


function add_notes_if_not_found()
    local has_notes = false
    for k,v in pairs(SMODS.Card.SUIT_LIST) do
        if v == NOTE_SUIT_VALUE then
            has_notes = true
        end
    end

    if not has_notes then
        table.insert(SMODS.Card.SUIT_LIST, NOTE_SUIT_INDEX, NOTE_SUIT_VALUE)
    end
end


local start_runref = Game.start_run;
function Game:start_run(args)
    local new_args = args or {}

    local saveTable = args.savetext or nil
    local selected_back = saveTable and saveTable.BACK.name or (args.challenge and args.challenge.deck and args.challenge.deck.type) or (self.GAME.viewed_back and self.GAME.viewed_back.name) or self.GAME.selected_back and self.GAME.selected_back.name or 'Red Deck'
    selected_back = Back(get_deck_from_name(selected_back))
    
    if not selected_back.effect.config.musical then
        new_args.challenge = {}
        if args.challenge then
            new_args.challenge = args.challenge
        end
    
        new_args.challenge.deck = {}
        if args.challenge.deck then
            new_args.challenge.deck = args.challenge.deck
        end
    
        new_args.challenge.deck.no_suits = {}
        if args.challenge.deck.no_suits then
            new_args.challenge.deck.no_suits = args.challenge.deck.no_suits
        end
    
        new_args.challenge.deck.no_suits[NOTE_SUIT_SYMBOL] = true
        table.remove(SMODS.Card.SUIT_LIST, NOTE_SUIT_INDEX)

        new_args.challenge.restrictions = {}
        if args.challenge.restrictions then
            new_args.challenge.restrictions = args.challenge.restrictions
        end
    
        new_args.challenge.restrictions.banned_cards = {}
        if args.challenge.restrictions.banned_cards then
            new_args.challenge.restrictions.banned_cards = args.challenge.restrictions.banned_cards
        end
        table.insert(new_args.challenge.restrictions.banned_cards, {id = "j_prideful_joker"})
        table.insert(new_args.challenge.restrictions.banned_cards, {id = "j_crystal_tuning_fork"})
        table.insert(new_args.challenge.restrictions.banned_cards, {id = "c_eclipse_tarot"})
    else
        add_notes_if_not_found()
    end

    sendDebugMessage("PLAYED SOUND")
    start_runref(self, new_args)
end


-- local main_menuref = Game.main_menu;
-- function Game:main_menu(change_context)
--     -- add_notes_if_not_found()
--     main_menuref(self, change_context)
-- end


local get_new_bossef = get_new_boss;
function get_new_boss()
    local new_boss = get_new_bossef()
    local selected_back = Back(get_deck_from_name(G.GAME.selected_back and G.GAME.selected_back.name or 'Red Deck'))
    if not selected_back.effect.config.musical then
        while new_boss == "bl_deaf" do
            new_boss = get_new_bossef()
        end
    end
    return new_boss
end


local clickref = Card.click;
function Card:click(change_context)
    if self.base.suit == "Notes" then
        pitch = 0.5 + 0.1 * self.base.id
        modded_play_sound('note', true, 0.75, pitch)
    end
    clickref(self)
end


local calculate_jokerref = Card.calculate_joker;
function Card:calculate_joker(context)
    local val = calculate_jokerref(self, context)
    if self.ability.set == "Joker" and not self.debuff then
        if context.individual then
            if context.cardarea == G.play then
                if self.ability.name ==  'Crystal Tuning Fork' and
                context.other_card:is_suit("Notes") and 
                pseudorandom('crystal_tuning_fork') < G.GAME.probabilities.normal/self.ability.extra.odds then
                    if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
                        G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                        G.E_MANAGER:add_event(Event({
                            trigger = 'before',
                            delay = 0.0,
                            func = (function()
                                    local card = create_card('Tarot',G.consumeables, nil, nil, nil, nil, nil, '8ba')
                                    card:add_to_deck()
                                    G.consumeables:emplace(card)
                                    G.GAME.consumeable_buffer = 0
                                return true
                            end)}))
                        card_eval_status_text(self, 'extra', nil, nil, nil, {message = localize('k_plus_tarot'), colour = G.C.PURPLE})
                    end
                    return {
                        card = self
                    }
                end
            end
        end
    end
    return val
end


function SMODS.INIT.MusicalSuit()
    local mod_id = "MusicalSuit"
    local musical_suit_mod = SMODS.findModByID(mod_id)
    SMODS.Sprite:new(mod_id .. "cards1", musical_suit_mod.path, '8BitDeck.png', 71, 95, 'asset_atli'):register()
    SMODS.Sprite:new(mod_id .. "cards2", musical_suit_mod.path, '8BitDeck_opt2.png', 71, 95, 'asset_atli'):register()
    SMODS.Sprite:new(mod_id .. "ui1", musical_suit_mod.path, 'ui_assets.png', 18, 18, 'asset_atli'):register()
    SMODS.Sprite:new(mod_id .. "ui2", musical_suit_mod.path, 'ui_assets_opt2.png', 18, 18, 'asset_atli'):register()
    SMODS.Card:new_suit('Notes', mod_id .. "cards1", mod_id .. "cards2", { y = 0 }, mod_id .. "ui1", mod_id .. "ui2", { x = 0, y = 0 }, 'D61BAF', 'D61BAF')

    loc_colour("mult", nil)
    G.ARGS.LOC_COLOURS["notes"] = G.C.SUITS.Notes

    local index={}
    for k,v in pairs(SMODS.Card.SUIT_LIST) do
       index[v]=k
    end
    NOTE_SUIT_VALUE = "Notes"
    NOTE_SUIT_INDEX = index["Notes"]

    for k,v in pairs(G.P_CARDS) do
        if v.suit == "Notes" then
            NOTE_SUIT_SYMBOL = string.sub(k, 1, 1)
        end
    end



    -- Prideful Joker
    local prideful_joker_def = {
        name = "Prideful Joker",
        text = {
            "Played cards with",
            "{C:notes}Note{} suit give",
            "{C:mult}+4{} Mult when scored"
        }
    }

    local prideful_joker = SMODS.Joker:new("Prideful Joker", "prideful_joker", {
        effect = "Suit Mult", extra = {s_mult = 4, suit = 'Notes'}, blueprint_compat = true, eternal_compat = true
    }, { x = 0, y = 0 }, prideful_joker_def, 1, 5)
    SMODS.Sprite:new("j_prideful_joker", musical_suit_mod.path, "j_prideful_joker.png", 71, 95, "asset_atli"):register();
    prideful_joker:register()


    
    -- Crystal Tuning Fork
    local crystal_tuning_fork_def = {
        name = "Crystal Tuning Fork",
        text = {
            "{C:green}1 in 5{} chance for",
            "played cards with",
            "{C:notes}Note{} suit to create",
            "a {C:purple}Tarot{} card when scored"
        }
    }

    local crystal_tuning_fork = SMODS.Joker:new("Crystal Tuning Fork", "crystal_tuning_fork", {
        extra = {odds = 3, Xmult = 2}, blueprint_compat = true, eternal_compat = true, unlock_condition = {type = 'modify_deck', extra = {count = 30, suit = 'Notes'}}
    }, { x = 0, y = 0 }, crystal_tuning_fork_def, 2, 7, false, false)
    SMODS.Sprite:new("j_crystal_tuning_fork", musical_suit_mod.path, "j_crystal_tuning_fork.png", 71, 95, "asset_atli"):register();
    crystal_tuning_fork:register()



    -- Musical Deck
    local musical_deck_def = {
        ["name"]="Musical Deck",
        ["text"]={
            [1]="Start with a Deck",
            [2]="containing some ",
            [3]="{C:notes}Notes{} suit cards"
        },
    }
    
    local musical_deck = SMODS.Deck:new("Musical Deck", "musical", {musical = true, atlas = "b_musical"}, {x = 0, y = 0}, musical_deck_def)
    SMODS.Sprite:new("b_musical", musical_suit_mod.path, "b_musical.png", 71, 95, "asset_atli"):register();
    musical_deck:register()



    --- Note Sounds
    register_sound("note", musical_suit_mod.path, "note.ogg")



    --- Deaf Blind
    local deaf_blind_def = {
        ["name"]="The Deaf",
        ["text"]={
            [1]="All Note cards",
            [2]="are debuffed"
        },
    }
    local deaf_blind = SMODS.Blind:new("The Deaf", "deaf", deaf_blind_def, 5, 2, {}, {suit = 'Notes'}, {x=0, y=0}, {min = 1, max = 10}, HEX('D61BAF'), true, mod_id .. "blinds")
    SMODS.Sprite:new(mod_id .. "blinds", musical_suit_mod.path, 'BlindChips.png', 34, 34, 'animation_atli', 21):register()
    deaf_blind:register()



    -- Eclipse Tarot
    local eclipse_tarot_def = {
        name = "The Eclipse",
        text = {
            "Converts up to",
            "{C:attention}3{} selected cards",
            "to {C:notes}Notes{}"
        }
    }

    local eclipse_tarot = SMODS.Tarot:new("The Eclipse", "eclipse_tarot", {suit_conv = 'Notes', max_highlighted = 3}, { x = 0, y = 0 }, eclipse_tarot_def, 3, 1.0, "Suit Conversion", true, true)
    SMODS.Sprite:new("c_eclipse_tarot", musical_suit_mod.path, "c_eclipse_tarot.png", 71, 95, "asset_atli"):register();
    eclipse_tarot:register()
end

----------------------------------------------
------------MOD CODE END---------------------