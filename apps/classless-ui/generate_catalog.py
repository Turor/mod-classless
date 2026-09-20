#!/usr/bin/env python3
"""Build CatalogData.lua from Talent.sql, SkillLineAbility.sql, and live class trainers.

Spellbook entries are restricted to spells class trainers actually teach
(acore_world.trainer_spell for trainer.Type = 0). SkillLineAbility is only
used to place a trainer spell into a spec. Talent trees stay Talent.dbc.
"""

import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DMLS = ROOT / "apps/patchgenerator/dmls/required"
OUT = Path(__file__).resolve().parent / "CatalogData.lua"

# DBC class id -> spec id string -> SkillLine id
SPEC_SKILLS = {
    6: {"blood": 770, "frost": 771, "unholy": 772},
    11: {"balance": 574, "feral": 134, "resto": 573},
    3: {"bm": 50, "marks": 163, "survival": 51},
    8: {"arcane": 237, "fire": 8, "frost": 6},
    2: {"holy": 56, "prot": 267, "ret": 184},
    5: {"disc": 613, "holy": 594, "shadow": 78},
    4: {"assassination": 253, "combat": 38, "subtlety": 39},
    7: {"elemental": 375, "enhancement": 373, "resto": 374},
    9: {"affliction": 355, "demonology": 354, "destruction": 593},
    1: {"arms": 26, "fury": 256, "prot": 257},
}

SKILL_TO_SPEC = {}
for class_id, specs in SPEC_SKILLS.items():
    for spec_id, skill in specs.items():
        SKILL_TO_SPEC[skill] = (class_id, spec_id)

# Combat/racial/profession skill lines that populate the Blizzard General tab.
GENERAL_SKILLS = {
    45, 46, 95, 101, 118, 124, 125, 126, 129, 162, 176, 220, 226, 228,
    733, 753, 754, 756, 760,
}

# Hunter/warlock/DK pet skill lines — these are pet abilities, not General.
PET_SKILLS = {
    188, 189, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214,
    215, 217, 218, 236, 251, 270, 653, 654, 655, 656, 758, 761, 763, 764,
    765, 766, 767, 768, 775, 780, 781, 782, 783, 784, 785, 786, 787, 788,
}

# Triggered/effect spells that share a player spell name (not real ranks).
BLOCKED_SPELLS = {
    42651,  # Army of the Dead summon trigger
}

# creature_default_trainer / trainer.Id -> ChrClasses id (Type=0 class trainers).
TRAINER_TO_CLASS = {
    1: 1, 2: 1,  # Warrior
    3: 2, 4: 2, 5: 2, 6: 2,  # Paladin
    7: 3, 8: 3,  # Hunter
    9: 4, 10: 4,  # Rogue
    11: 5, 12: 5,  # Priest
    13: 6,  # Death Knight
    14: 7, 15: 7,  # Shaman
    16: 8, 17: 8,  # Mage
    31: 9, 32: 9,  # Warlock
    33: 11, 34: 11,  # Druid
}

TUPLE_RE = re.compile(r"\(([^()]+)\)")


def parse_tuples(path: Path):
    text = path.read_text(encoding="utf-8", errors="replace")
    rows = []
    for m in TUPLE_RE.finditer(text):
        parts = [p.strip() for p in m.group(1).split(",")]
        try:
            rows.append([int(p) for p in parts])
        except ValueError:
            continue
    return rows


def lua_list(nums):
    return "{" + ",".join(str(n) for n in nums) + "}"


def load_trainer_spells(path: Path):
    by_class = defaultdict(set)
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        parts = line.split()
        if len(parts) < 2:
            continue
        trainer_id, spell = int(parts[0]), int(parts[1])
        class_id = TRAINER_TO_CLASS.get(trainer_id)
        if not class_id or spell in BLOCKED_SPELLS:
            continue
        by_class[class_id].add(spell)
    return by_class


def main():
    talent_rows = parse_tuples(DMLS / "Talent.sql")
    sla_rows = parse_tuples(DMLS / "SkillLineAbility.sql")

    talent_spell_ids = set()
    talents = defaultdict(list)
    for row in talent_rows:
        if len(row) < 23:
            continue
        tid, tab, tier, col = row[0], row[1], row[2], row[3]
        ranks = [x for x in row[4:13] if x]
        if not ranks:
            continue
        for sid in ranks:
            talent_spell_ids.add(sid)
        prereq = row[13] or 0
        prereq_rank = row[16] or 0
        talents[tab].append(
            {
                "id": tid,
                "t": tier,
                "c": col,
                "r": ranks,
                "p": prereq,
                "pr": prereq_rank,
            }
        )

    ATTR0_PASSIVE = 0x00000040
    # Trade skill recipe — shown in the recipe list, not the spellbook.
    ATTR0_IS_TRADESKILL = 0x00000020
    # Hidden in UI — not visible in spellbook or aura bar (Spell.dbc attributes bit 7).
    ATTR0_DO_NOT_DISPLAY = 0x00000080
    spell_attr0 = {}
    spell_sql = DMLS / "Spell.sql"
    spell_text = ""
    if spell_sql.exists():
        spell_text = spell_sql.read_text(encoding="utf-8", errors="replace")
        for m in re.finditer(
            r"\((\d+),\s*(-?\d+),\s*(-?\d+),\s*(-?\d+),\s*(-?\d+)", spell_text
        ):
            spell_attr0[int(m.group(1))] = int(m.group(5))

    def in_spellbook(spell_id):
        if spell_id in BLOCKED_SPELLS:
            return False
        attr = spell_attr0.get(spell_id, 0)
        if attr & ATTR0_DO_NOT_DISPLAY:
            return False
        if attr & ATTR0_IS_TRADESKILL:
            return False
        return True

    def is_passive(spell_id):
        return (spell_attr0.get(spell_id, 0) & ATTR0_PASSIVE) != 0

    trainer_by_class = load_trainer_spells(Path(__file__).resolve().parent / "class_trainer_spells.txt")
    trainer_all = set()
    for s in trainer_by_class.values():
        trainer_all |= s

    sla_by_spell = defaultdict(list)
    for row in sla_rows:
        if len(row) < 3:
            continue
        skill, spell = int(row[1]), int(row[2])
        acq = int(row[9]) if len(row) > 9 else 0
        sla_by_spell[spell].append((skill, acq))

    def resolve_spec(class_id, spell):
        class_specs = SPEC_SKILLS.get(class_id) or {}
        named = None
        for skill, _acq in sla_by_spell.get(spell, []):
            mapped = SKILL_TO_SPEC.get(skill)
            if not mapped:
                continue
            sla_class, sla_spec = mapped
            if sla_class == class_id:
                return sla_spec
            if sla_spec in class_specs:
                named = sla_spec
        return named

    spells = defaultdict(lambda: defaultdict(list))
    placed = defaultdict(set)
    general = []
    general_seen = set()
    pet_spells = []
    pet_seen = set()

    def spell_is_pet(spell):
        for skill, _acq in sla_by_spell.get(spell, []):
            if skill in PET_SKILLS:
                return True
        return False

    for class_id, trained in trainer_by_class.items():
        for spell in trained:
            if not in_spellbook(spell):
                continue
            spec_id = resolve_spec(class_id, spell)
            if spec_id:
                if spell not in placed[class_id]:
                    spells[class_id][spec_id].append(spell)
                    placed[class_id].add(spell)
            elif spell_is_pet(spell):
                if spell not in pet_seen:
                    pet_spells.append(spell)
                    pet_seen.add(spell)

    # Spell.dbc SpellFamilyName (spell_class_set) -> ChrClasses. Classless SLA
    # dumps class_mask=-1, so family is what keeps Smite off paladin Holy.
    FAMILY_TO_CLASS = {
        3: 8, 4: 1, 5: 9, 6: 5, 7: 11, 8: 4, 9: 3, 10: 2, 11: 7, 15: 6,
    }
    start_ids = set()
    for spell, entries in sla_by_spell.items():
        if any(acq == 2 and not is_passive(spell) for _sk, acq in entries):
            start_ids.add(spell)

    def parse_sql_fields(chunk):
        fields = []
        cur = []
        in_s = False
        i = 0
        while i < len(chunk) and not (not in_s and chunk[i] == ")" and len(fields) >= 208):
            ch = chunk[i]
            if in_s:
                if ch == "\\" and i + 1 < len(chunk):
                    cur.append(chunk[i + 1])
                    i += 2
                    continue
                if ch == "'":
                    in_s = False
                    i += 1
                    continue
                cur.append(ch)
                i += 1
                continue
            if ch == "'":
                in_s = True
                i += 1
                continue
            if ch == ",":
                fields.append("".join(cur).strip())
                cur = []
                i += 1
                continue
            cur.append(ch)
            i += 1
        if cur:
            fields.append("".join(cur).strip())
        return fields

    spell_family = {}
    if spell_sql.exists() and start_ids:
        for m in re.finditer(r"\((\d+),", spell_text):
            sid = int(m.group(1))
            if sid not in start_ids:
                continue
            fields = parse_sql_fields(spell_text[m.end() :])
            # id already consumed; field 0 in fields is category => spell_class_set is index 207
            if len(fields) > 207:
                try:
                    spell_family[sid] = int(fields[207])
                except ValueError:
                    pass
            if len(spell_family) >= len(start_ids):
                break

    for spell, entries in sla_by_spell.items():
        if not in_spellbook(spell):
            continue
        is_start = False
        sla_class = None
        sla_spec = None
        for skill, acq in entries:
            if acq == 2 and not is_passive(spell):
                is_start = True
                mapped = SKILL_TO_SPEC.get(skill)
                if mapped:
                    sla_class, sla_spec = mapped
        if not is_start:
            continue
        fam = spell_family.get(spell, 0)
        class_id = FAMILY_TO_CLASS.get(fam) or sla_class
        if not class_id:
            continue
        if spell in placed[class_id]:
            continue
        if any(spell in s for c, s in trainer_by_class.items() if c != class_id):
            continue
        spec_id = resolve_spec(class_id, spell) or sla_spec
        if not spec_id:
            if spell_is_pet(spell) and spell not in pet_seen:
                pet_spells.append(spell)
                pet_seen.add(spell)
            continue
        spells[class_id][spec_id].append(spell)
        placed[class_id].add(spell)

    # Blizzard General tab: racials, Dodge/Parry/Block, Dual Wield, Shoot/Throw,
    # First Aid, plus hardcoded Auto Attack and Turoran extras. SPELL_ATTR0_DO_NOT_DISPLAY
    # already excluded. Weapon/armor skill leftover is not General.
    for spell, entries in sla_by_spell.items():
        if not in_spellbook(spell):
            continue
        if any(sk in GENERAL_SKILLS for sk, _acq in entries):
            if spell not in general_seen:
                general.append(spell)
                general_seen.add(spell)
    for extra in (6603, 2764, 3018, 5019, 360001, 360002, 360003):
        if in_spellbook(extra) and extra not in general_seen:
            general.append(extra)
            general_seen.add(extra)

    for class_id in spells:
        for spec_id in spells[class_id]:
            spells[class_id][spec_id].sort()
    general.sort()
    pet_spells.sort()

    lines = [
        "-- Generated by generate_catalog.py. Do not edit by hand.",
        "local C = ClasslessUICatalog",
        "if not C then return end",
        "C.spells = {",
    ]
    for class_id in sorted(spells):
        lines.append(f"  [{class_id}] = {{")
        for spec_id in sorted(spells[class_id]):
            ids = spells[class_id][spec_id]
            lines.append(f"    {spec_id} = {lua_list(ids)},")
        lines.append("  },")
    lines.append("}")
    lines.append(f"C.generalSpells = {lua_list(general)}")
    lines.append(f"C.petSpells = {lua_list(pet_spells)}")
    lines.append("C.talents = {")
    for tab in sorted(talents):
        lines.append(f"  [{tab}] = {{")
        nodes = sorted(talents[tab], key=lambda n: (n["t"], n["c"], n["id"]))
        for n in nodes:
            lines.append(
                "    {id=%d,t=%d,c=%d,r=%s,p=%d,pr=%d},"
                % (n["id"], n["t"], n["c"], lua_list(n["r"]), n["p"], n["pr"])
            )
        lines.append("  },")
    lines.append("}")
    lines.append("C.petTabs = {409,410,411}")
    lines.append("C.spellSet = {}")
    lines.append("for classId, specs in pairs(C.spells) do")
    lines.append("  for specId, ids in pairs(specs) do")
    lines.append("    local kept = {}")
    lines.append("    for i = 1, #ids do")
    lines.append("      local sid = ids[i]")
    lines.append("      if not (C.blockedSpells and C.blockedSpells[sid]) then")
    lines.append("        kept[#kept + 1] = sid")
    lines.append("        C.spellSet[sid] = true")
    lines.append("      end")
    lines.append("    end")
    lines.append("    C.spells[classId][specId] = kept")
    lines.append("  end")
    lines.append("end")
    lines.append("do")
    lines.append("  local kept = {}")
    lines.append("  for i = 1, #(C.generalSpells or {}) do")
    lines.append("    local sid = C.generalSpells[i]")
    lines.append("    if not (C.blockedSpells and C.blockedSpells[sid]) then")
    lines.append("      kept[#kept + 1] = sid")
    lines.append("      C.spellSet[sid] = true")
    lines.append("    end")
    lines.append("  end")
    lines.append("  C.generalSpells = kept")
    lines.append("  C.generalSet = {}")
    lines.append("  for i = 1, #kept do C.generalSet[kept[i]] = true end")
    lines.append("end")
    lines.append("do")
    lines.append("  local kept = {}")
    lines.append("  for i = 1, #(C.petSpells or {}) do")
    lines.append("    local sid = C.petSpells[i]")
    lines.append("    if not (C.blockedSpells and C.blockedSpells[sid]) then")
    lines.append("      kept[#kept + 1] = sid")
    lines.append("      C.spellSet[sid] = true")
    lines.append("    end")
    lines.append("  end")
    lines.append("  C.petSpells = kept")
    lines.append("end")
    lines.append("C.talentById = {}")
    lines.append("for tabId, nodes in pairs(C.talents) do")
    lines.append("  for i = 1, #nodes do")
    lines.append("    local n = nodes[i]")
    lines.append("    n.tabId = tabId")
    lines.append("    C.talentById[n.id] = n")
    lines.append("  end")
    lines.append("end")
    lines.append("")
    lines.append("local AIO = AIO or require(\"AIO\")")
    lines.append("if AIO.IsMainState and AIO.IsMainState() and AIO.AddAddon then")
    lines.append("  AIO.AddAddon()")
    lines.append("end")
    lines.append("")
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    n_spells = sum(len(ids) for specs in spells.values() for ids in specs.values())
    n_talents = sum(len(v) for v in talents.values())
    print(f"wrote {OUT} spells={n_spells} talent_nodes={n_talents}")


if __name__ == "__main__":
    main()
