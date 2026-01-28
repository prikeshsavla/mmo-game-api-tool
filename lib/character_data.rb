# frozen_string_literal: true

# Data structure representing a character's state and attributes retrieved from the API.
CharacterData = Struct.new('CharacterData', :name, :account, :skin, :level, :xp, :max_xp, :gold, :speed, :mining_level,
                           :mining_xp, :mining_max_xp, :woodcutting_level, :woodcutting_xp, :woodcutting_max_xp,
                           :fishing_level, :fishing_xp, :fishing_max_xp, :weaponcrafting_level, :weaponcrafting_xp,
                           :weaponcrafting_max_xp, :gearcrafting_level, :gearcrafting_xp, :gearcrafting_max_xp,
                           :jewelrycrafting_level, :jewelrycrafting_xp, :jewelrycrafting_max_xp, :cooking_level,
                           :cooking_xp, :cooking_max_xp, :alchemy_level, :alchemy_xp, :alchemy_max_xp, :hp, :max_hp,
                           :haste, :critical_strike, :wisdom, :prospecting, :initiative, :threat, :attack_fire,
                           :attack_earth, :attack_water, :attack_air, :dmg, :dmg_fire, :dmg_earth, :dmg_water,
                           :dmg_air, :res_fire, :res_earth, :res_water, :res_air, :effects, :x, :y, :layer, :map_id,
                           :cooldown, :cooldown_expiration, :weapon_slot, :rune_slot, :shield_slot, :helmet_slot,
                           :body_armor_slot, :leg_armor_slot, :boots_slot, :ring1_slot, :ring2_slot, :amulet_slot,
                           :artifact1_slot, :artifact2_slot, :artifact3_slot, :utility1_slot, :utility1_slot_quantity,
                           :utility2_slot, :utility2_slot_quantity, :bag_slot, :task, :task_type, :task_progress,
                           :task_total, :inventory_max_items, :inventory) do
  def diff(old_data)
    result = {}

    old_data.to_h.each { |k, v| result[k] = self[k] if self[k] != v }
    result[:inventory] = inventory - old_data.inventory if inventory && old_data.inventory
    result
  end

  def self.from_hash(hash)
    return nil if hash.nil?

    values = members.map { |m| hash[m.to_s] }
    CharacterData.new(*values)
  end
end
