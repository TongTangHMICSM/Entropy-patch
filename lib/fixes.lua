SMODS.Joker:take_ownership("j_cry_redeo", {
  loc_vars = function(self, q, center)
    local ante_mod = center.ability.extra.ante_reduction
    if ante_mod > 0 then
      ante_mod = "-"..number_format(ante_mod)
    else
      ante_mod = "+"..number_format(-ante_mod)
    end
    if G.GAME.ReverseRedeo then
      ante_mod = "+1"
    end
    return {
      vars = {
        ante_mod,
				number_format(center.ability.extra.money_req),
				number_format(center.ability.extra.money_remaining),
				number_format(center.ability.extra.money_mod),
			},
    }
  end,
  calculate = function(self, card, context)
		if context.cry_ease_dollars and to_big(context.cry_ease_dollars) < to_big(0) and not context.blueprint then
			card.ability.extra.money_remaining =
				lenient_bignum(to_big(card.ability.extra.money_remaining) - context.cry_ease_dollars)
			local ante_mod = 0
			while to_big(card.ability.extra.money_remaining) >= to_big(card.ability.extra.money_req) do
				card.ability.extra.money_remaining =
					lenient_bignum(to_big(card.ability.extra.money_remaining) - card.ability.extra.money_req)
				card.ability.extra.money_req =
					lenient_bignum(to_big(card.ability.extra.money_req) + card.ability.extra.money_mod)
				card.ability.extra.money_mod = lenient_bignum(math.ceil(to_big(card.ability.extra.money_mod) * 1.06))
				ante_mod = lenient_bignum(ante_mod - to_big(card.ability.extra.ante_reduction))
			end
			ease_ante(ante_mod)
			return nil, true
		end
		if context.forcetrigger then
			ease_ante(card.ability.extra.ante_reduction)
		end
	end,
},true)

function get_highest(hand)
  local highest = nil
  if type(hand) ~= "table" then return {} end
  for k, v in ipairs(hand or {}) do
    if not highest or v:get_nominal() > highest:get_nominal() then
      highest = v
    end
  end
  if #hand > 0 then return {{highest}} else return {} end
end

function UIElement:update_text()
  if self.config and self.config.text and not self.config.text_drawable then
      self.config.lang = self.config.lang or G.LANG
      if self.config.font then
        self.config.text_drawable = love.graphics.newText(self.config.font.FONT, {G.C.WHITE,self.config.text})
      else
        self.config.text_drawable = love.graphics.newText(self.config.lang.font.FONT, {G.C.WHITE,self.config.text})
      end
  end

  if self.config.ref_table and self.config.ref_table[self.config.ref_value] ~= self.config.prev_value then
      self.config.text = tostring(self.config.ref_table[self.config.ref_value])
      self.config.text_drawable:set(self.config.text)
      if type(self.config.prev_value) == "string" and type(self.config.text) ~= "string" then
        if not self.config.no_recalc and self.config.prev_value and string.len(self.config.prev_value) ~= string.len(self.config.text) then self.UIBox:recalculate() end
      else
        self.config.prev_value = number_format(self.config.prev_value)
        self.UIBox:recalculate()
      end
      self.config.prev_value = self.config.ref_table[self.config.ref_value] 
  end
end

local ref = SMODS.get_blind_amount
function SMODS.get_blind_amount(ante)
  if to_big(ante) <= to_big(8) then 
    return ref(to_number(ante))
  else --disgusting hook because the patches sometimes fail
    local k = to_big(0.75)
    local scale = G.GAME.modifiers.scaling
    local amounts = {
        to_big(300),
        to_big(700 + 100*scale),
        to_big(1400 + 600*scale),
        to_big(2100 + 2900*scale),
        to_big(15000 + 5000*scale*math.log(scale)),
        to_big(12000 + 8000*(scale+1)*(0.4*scale)),
        to_big(10000 + 25000*(scale+1)*((scale/4)^2)),
        to_big(50000 * (scale+1)^2 * (scale/7)^2)
    }
    local a, b, c, d = amounts[8], amounts[8]/amounts[7], ante-8, 1 + 0.2*(ante-8)
    local amount = math.floor(a*(b + (b*k*c)^d)^c)
    if ( to_big(amount) < to_big(R and R.E_MAX_SAFE_INTEGER or 9e15)) then
	  local amount_log = type(amount) == "table" and amount:log10() or math.log10(amount)
      local exponent = to_big(10)^(math.floor(amount_log - to_big(1)))
	  if type(exponent) == "table" then exponent = exponent:to_number() end
      amount = math.floor(amount / exponent)
	  if type(amount) == "table" then amount = amount:to_number() end
	  amount = amount * exponent
    end
    if type(amount) == "table" then amount:normalize() end
    return amount
  end
end

local updateht_ref= update_hand_text
function update_hand_text( args1, args2)
    if args2.handname == localize("cry_None", "poker_hands") and G.GAME.badarg and G.GAME.badarg["cry_None"] then
      args2.handname = ""
      args2.chips = "bad"
      args2.mult = "arg"
    else
      updateht_ref(args1, args2)
    end
end

SMODS.Blind:take_ownership("cry_pin", {
  recalc_debuff = function(self, card, from_blind)
		if
			(card.area == G.jokers)
			and not G.GAME.blind.disabled
			and (
				card.config.center.rarity == 4
				or card.config.center.rarity == "cry_epic"
				or card.config.center.rarity == "cry_exotic"
        or card.config.center.rarity == "entr_reverse_legendary"
        or card.config.center.rarity == "entr_entropic"
			)
		then
			return true
		end
		return false
	end,
},true)

local ref = localize
function localize(args, misc_cat)
  return ref(args or {}, misc_cat)
end

SMODS.Booster:take_ownership("p_cry_code_normal_1", {
  create_card = function()
      if G.GAME.interpolate_cards and #G.GAME.interpolate_cards > 0 then
        for i, v in pairs(G.GAME.interpolate_cards) do
            local num = pseudorandom("twisted_interpolate")
            if num <= 0.03 then
                local c = v
                return create_card(G.P_CENTERS[c].set, area or G.pack_cards, nil, nil, true, true, c)
            end
        end
    end
    return create_card("Code", G.pack_cards, nil, nil, true, true, nil, "cry_program_1")
  end
}, true)
SMODS.Booster:take_ownership("p_cry_code_normal_2", {
  create_card = function()
      if G.GAME.interpolate_cards and #G.GAME.interpolate_cards > 0 then
        for i, v in pairs(G.GAME.interpolate_cards) do
            local num = pseudorandom("twisted_interpolate")
            if num <= 0.03 then
                local c = v
                return create_card(G.P_CENTERS[c].set, area or G.pack_cards, nil, nil, true, true, c)
            end
        end
    end
    return create_card("Code", G.pack_cards, nil, nil, true, true, nil, "cry_program_1")
  end
}, true)
SMODS.Booster:take_ownership("p_cry_code_jumbo_1", {
  create_card = function()
      if G.GAME.interpolate_cards and #G.GAME.interpolate_cards > 0 then
        for i, v in pairs(G.GAME.interpolate_cards) do
            local num = pseudorandom("twisted_interpolate")
            if num <= 0.03 then
                local c = v
                return create_card(G.P_CENTERS[c].set, area or G.pack_cards, nil, nil, true, true, c)
            end
        end
    end
    return create_card("Code", G.pack_cards, nil, nil, true, true, nil, "cry_program_1")
  end
}, true)
SMODS.Booster:take_ownership("p_cry_code_mega_1", {
  create_card = function()
      if G.GAME.interpolate_cards and #G.GAME.interpolate_cards > 0 then
        for i, v in pairs(G.GAME.interpolate_cards) do
            local num = pseudorandom("twisted_interpolate")
            if num <= 0.03 then
                local c = v
                return create_card(G.P_CENTERS[c].set, area or G.pack_cards, nil, nil, true, true, c)
            end
        end
    end
    return create_card("Code", G.pack_cards, nil, nil, true, true, nil, "cry_program_1")
  end
}, true)

local mod_mult_ref = mod_mult
function mod_mult(_mult)
  if _mult then return mod_mult_ref(_mult) end
  return 1
end

local mod_chips_ref = mod_chips
function mod_chips(_chips)
  if _chips then return mod_chips_ref(_chips) end
  return 1
end

local get_areas_ref = SMODS.get_card_areas
function SMODS.get_card_areas(...)
  local ret = get_areas_ref(...)
  for i, v in pairs(ret) do
    v.cards = v.cards or {}
  end
  return ret
end

-- ---------------------------------------------------------------------------
-- Ghost / empty hand cards
-- ---------------------------------------------------------------------------
-- A card that is in G.hand.cards (so it eats a slot and counts toward hand size) but is
-- neither drawn nor clickable. It comes from an interrupted spawn: the `_card.states.visible
-- = nil` + deferred `_card:start_materialize()` pattern loses its event when the queue is
-- flushed by a state change, or `start_materialize` runs but its trailing restore event is
-- dropped, which leaves `states.hover.can = false` on a visible-but-dead card.
--
-- A card is only healed after it has stayed stuck for several consecutive checks, so a card
-- that is legitimately mid-materialize is never touched.
local entr_ghost_ticks = setmetatable({}, { __mode = "k" })
-- Polled every 0.25s from Game:update, so ~2s of being stuck. A full start_materialize
-- sequence settles in well under that, so an in-flight card is never touched.
local ENTR_GHOST_TICKS_NEEDED = 8

local function entr_card_is_ghost(c)
    if not c or not c.states then return false end
    if c.removed or c.dissolved or c.getting_sliced then return false end
    -- no sprite to draw at all (center is a missing/unloaded key)
    if not c.children or not c.children.center then return true end
    -- never drawn at all (still counts against the hand limit)
    if c.states.visible ~= true then return true end
    -- start_materialize set dissolve = 1 and its ease-back event was lost
    if (tonumber(c.dissolve) or 0) > 0.98 then return true end
    -- visible but unhoverable/unclickable
    if c.states.hover and c.states.hover.can == false then return true end
    if c.states.collide and c.states.collide.can == false then return true end
    return false
end

local function entr_repair_card(c)
    c.states.visible = true
    for _, key in ipairs({ "hover", "collide", "click", "drag", "focus" }) do
        c.states[key] = c.states[key] or {}
        c.states[key].can = true
    end
    c.dissolve = 0
    c.getting_sliced = nil
    -- A card loaded with an unknown center never built a sprite, so it could never be drawn.
    -- Rebuild it, falling back to a plain card front so the slot is at least visible/usable.
    if not c.children or not c.children.center then
        local ok = pcall(function() c:set_sprites(c.config.center, c.config.card) end)
        if not ok or not c.children.center then
            pcall(function()
                c.config.center = G.P_CENTERS.c_base
                c.config.center_key = "c_base"
                c:set_sprites(G.P_CENTERS.c_base, c.config.card or G.P_CARDS["S_2"])
            end)
        end
    end
end

---Heals hand cards left in an unusable state (invisible and/or unclickable) and drops
---duplicate/missing entries that also inflate the perceived hand size.
---@return boolean dirty Whether anything was changed.
function Entropy.repair_hand_cards()
    if not (G.hand and G.hand.cards) then return false end
    local seen, dirty = {}, false
    for i = #G.hand.cards, 1, -1 do
        local c = G.hand.cards[i]
        if not c then
            table.remove(G.hand.cards, i)
            dirty = true
        elseif seen[c] then
            -- the same card object listed twice: only one of them is ever drawn
            table.remove(G.hand.cards, i)
            dirty = true
        else
            seen[c] = true
            if entr_card_is_ghost(c) then
                entr_ghost_ticks[c] = (entr_ghost_ticks[c] or 0) + 1
                if entr_ghost_ticks[c] >= ENTR_GHOST_TICKS_NEEDED then
                    entr_ghost_ticks[c] = nil
                    entr_repair_card(c)
                    dirty = true
                end
            else
                entr_ghost_ticks[c] = nil
            end
        end
    end
    if dirty then
        G.hand:align_cards()
        -- a repaired hand can leave the highlight/selection out of sync
        if G.STATE == G.STATES.SELECTING_HAND then
            for j = #G.hand.highlighted, 1, -1 do
                local c = G.hand.highlighted[j]
                if not c or c.removed or c.area ~= G.hand then
                    table.remove(G.hand.highlighted, j)
                end
            end
            G.hand:parse_highlighted()
        end
    end
    return dirty
end

---Drops cards that are still listed in G.hand.cards but already belong to another area
---(a mod moved them without removing them from the hand), which otherwise leave dead slots
---behind. Only pruned when the card is confirmed to be in that other area's list, so a card
---mid-transition is never dropped.
function Entropy.prune_orphan_hand_cards()
    if not (G.hand and G.hand.cards) then return false end
    local dirty = false
    for i = #G.hand.cards, 1, -1 do
        local c = G.hand.cards[i]
        if c and not c.area then
            -- listed in the hand but its area was never (or wrongly) assigned: it will not
            -- render or receive input. Re-attach it rather than dropping the card.
            pcall(function() c:set_card_area(G.hand) end)
            c.area = c.area or G.hand
            dirty = true
        end
        local other = c and c.area
        if other and other ~= G.hand and other.cards then
            for _, v in ipairs(other.cards) do
                if v == c then
                    table.remove(G.hand.cards, i)
                    dirty = true
                    break
                end
            end
        end
    end
    if dirty then G.hand:align_cards() end
    return dirty
end

-- ---------------------------------------------------------------------------
-- Select button for consumables inside a booster pack
-- ---------------------------------------------------------------------------
-- There are two separate button UIs on a pack card:
--   * hovering -> G.UIDEF.card_focus_ui  (SMODS patches it in lovely/booster.toml)
--   * clicking -> Card:highlight -> children.use_button -> G.UIDEF.use_and_sell_buttons
-- Both of SMODS' patches only offer a Select button when SMODS.card_select_area returns an
-- area, which in turn requires the center / ConsumableType / pack to declare `select_card`.
-- No Entropy pack declares one, so hovering an inverted consumable showed a lone Use button
-- and there was no way to take it instead.
--
-- Providing the default here gives every consumable in an open pack a Select button next to
-- its Use button ("can_also_use"), without having to declare select_card on every pack and
-- every ConsumableType.
local entr_card_select_area_ref = SMODS.card_select_area
if type(entr_card_select_area_ref) == "function" then
    function SMODS.card_select_area(card, pack)
        local area, can_also_use = entr_card_select_area_ref(card, pack)
        if area then return area, can_also_use end
        if not (card and card.ability and card.ability.consumeable) then return area, can_also_use end
        if not (G.pack_cards and card.area == G.pack_cards) then return area, can_also_use end
        if card.config.center.hidden or card.config.center.no_select then return area, can_also_use end
        -- "consumeables" is the area Card:selectable_from_pack expects; true keeps the Use button.
        return "consumeables", true
    end
end
