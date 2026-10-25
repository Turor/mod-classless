#!/usr/bin/env python3
"""Generate the Hero class (class ID 10) data for Turoran Classless.

Inputs (snapshot of Standard prod, see inputs/README.md):
  inputs/player_class_stats.tsv   Class Level BaseHP BaseMana Str Agi Sta Int Spi
  inputs/gt*_dbc.tsv              world DB gt*_dbc overrides (ID Data)
  inputs/CharStartOutfit.dbc      server/client CharStartOutfit.dbc (stock + classless)
  inputs/CharBaseInfo.dbc         stock CharBaseInfo.dbc
  inputs/playercreateinfo*.tsv    world DB playercreateinfo / _action

Outputs:
  ../../data/sql/db-world/hero_class.sql                       server (world DB, auto-applied by DBUpdater)
  ../patchgenerator/dmls/migrations/V023__HeroClass.sql        client DBC sqlite (Flyway)
  --client-dbc DIR                                             ready-built client DBCs for patch-n
  hero_numbers.md                                              derivation tables for review

Run:  python3 gen_hero.py [--client-dbc OUTDIR] [--chrclasses-sql ../patchgenerator/dmls/required/ChrClasses.sql]
"""
import argparse, os, re, struct, sys

HERE = os.path.dirname(os.path.abspath(__file__))
INP = os.path.join(HERE, 'inputs')
HERO = 10
# Primary power (ChrClasses DisplayPower): POWER_MANA, per gauntlet-design.md section 12. Other pools stay
# live through mod-classless OnPlayerHasActivePowerType(); 127 (POWER_ALL) is not a valid class power.
HERO_DISPLAY_POWER = 0
CLASS_NAMES = {1: 'Warrior', 2: 'Paladin', 3: 'Hunter', 4: 'Rogue', 5: 'Priest', 6: 'Death Knight',
               7: 'Shaman', 8: 'Mage', 9: 'Warlock', 11: 'Druid'}
NON_DK = [1, 2, 3, 4, 5, 7, 8, 9, 11]
HYBRID_REF = [2, 11]                      # Paladin + Druid: the hybrid budget / ratio reference
PLAYABLE_RACES = [1, 2, 3, 4, 5, 6, 7, 8, 10, 11]
RACE_NAMES = {1: 'Human', 2: 'Orc', 3: 'Dwarf', 4: 'Night Elf', 5: 'Undead', 6: 'Tauren', 7: 'Gnome',
              8: 'Troll', 10: 'Blood Elf', 11: 'Draenei'}
HERO_WEAPON = 2361      # Battleworn Hammer (Paladin starter 2H mace)
HEARTHSTONE = 6948
GT_PER_LEVEL = ['gtchancetomeleecrit_dbc', 'gtchancetospellcrit_dbc', 'gtoctregenhp_dbc',
                'gtregenhpperspt_dbc', 'gtregenmpperspt_dbc']
GT_BASE = ['gtchancetomeleecritbase_dbc', 'gtchancetospellcritbase_dbc']
GT_FILES = {'gtchancetomeleecrit_dbc': 'gtChanceToMeleeCrit.dbc', 'gtchancetospellcrit_dbc': 'gtChanceToSpellCrit.dbc',
            'gtoctregenhp_dbc': 'gtOCTRegenHP.dbc', 'gtregenhpperspt_dbc': 'gtRegenHPPerSpt.dbc',
            'gtregenmpperspt_dbc': 'gtRegenMPPerSpt.dbc', 'gtchancetomeleecritbase_dbc': 'gtChanceToMeleeCritBase.dbc',
            'gtchancetospellcritbase_dbc': 'gtChanceToSpellCritBase.dbc',
            'gtoctclasscombatratingscalar_dbc': 'gtOCTClassCombatRatingScalar.dbc'}


def tsv(name):
    with open(os.path.join(INP, name)) as f:
        return [l.rstrip('\n').split('\t') for l in f if l.strip()]


def mean(xs):
    return sum(xs) / len(xs)


# ---------------------------------------------------------------- stats
def hero_stats():
    rows = {(int(r[0]), int(r[1])): [int(x) for x in r[2:]] for r in tsv('player_class_stats.tsv')}
    max_level = max(l for (c, l) in rows if c == 1)
    out = {}
    for lvl in range(1, max_level + 1):
        avg = [mean([rows[(c, lvl)][2 + i] for c in NON_DK]) for i in range(5)]
        target = round(mean([sum(rows[(c, lvl)][2:7]) for c in HYBRID_REF]))
        scale = target / sum(avg)
        raw = [a * scale for a in avg]
        ints = [int(x) for x in raw]
        # largest remainder so the five stats add up to the hybrid budget exactly
        for i in sorted(range(5), key=lambda i: raw[i] - ints[i], reverse=True)[:target - sum(ints)]:
            ints[i] += 1
        base_hp = rows[(1, lvl)][0]     # classless: every class already uses the Warrior BaseHP curve
        base_mana = rows[(8, lvl)][1]   # classless: every class already uses the Mage BaseMana curve
        out[lvl] = (base_hp, base_mana, ints, target, [round(a, 1) for a in avg])
    return rows, out


# ---------------------------------------------------------------- gt tables
def gt_values():
    res = {}
    for t in GT_PER_LEVEL:
        v = {int(a): float(b) for a, b in tsv(t + '.tsv')}
        res[t] = {lvl: mean([v[(c - 1) * 100 + lvl - 1] for c in HYBRID_REF]) for lvl in range(1, 101)}
    for t in GT_BASE:
        v = {int(a): float(b) for a, b in tsv(t + '.tsv')}
        res[t] = mean([v[c - 1] for c in HYBRID_REF])
    v = {int(a): float(b) for a, b in tsv('gtoctclasscombatratingscalar_dbc.tsv')}
    base = min(v)   # 1-based IDs in the world table: ID = (class-1)*32 + rating + base
    res['gtoctclasscombatratingscalar_dbc'] = {
        r: mean([v[(c - 1) * 32 + r + base] for c in HYBRID_REF]) for r in range(32)}
    res['_scalar_base'] = base
    return res


# ---------------------------------------------------------------- outfits
def read_outfits():
    b = open(os.path.join(INP, 'CharStartOutfit.dbc'), 'rb').read()
    n, fc, rs, ss = struct.unpack('<4I', b[4:20])
    assert fc == 77 and rs == 296, (fc, rs)
    data = b[20:20 + n * rs]
    rows = []
    for i in range(n):
        r = data[i * rs:(i + 1) * rs]
        rid, race, cls, sex, oid = struct.unpack('<I4B', r[:8])
        items = list(struct.unpack('<24i', r[8:104]))
        disp = list(struct.unpack('<24i', r[104:200]))
        inv = list(struct.unpack('<24i', r[200:296]))
        rows.append(dict(id=rid, race=race, cls=cls, sex=sex, outfit=oid, items=items, disp=disp, inv=inv))
    return rows, b[20 + n * rs:]


def hero_outfits(rows):
    display = {}
    for r in rows:
        for it, d, iv in zip(r['items'], r['disp'], r['inv']):
            if it > 0:
                display.setdefault(it, (d, iv))
    by = {(r['race'], r['cls'], r['sex']): r for r in rows}
    next_id = max(r['id'] for r in rows) + 1
    out = []
    for race in PLAYABLE_RACES:
        for sex in (0, 1):
            src = by.get((race, 1, sex)) or by.get((race, 2, sex))   # Warrior armour, Blood Elf -> Paladin
            src_cls = 1 if (race, 1, sex) in by else 2
            armour = [(it, d, iv) for it, d, iv in zip(src['items'], src['disp'], src['inv'])
                      if it > 0 and iv in (4, 5, 7, 8, 20)]         # shirt/chest/legs/feet/robe
            items = armour + [(HERO_WEAPON,) + display[HERO_WEAPON], (HEARTHSTONE,) + display[HEARTHSTONE]]
            items += [(-1, -1, -1)] * (24 - len(items))   # stock padding
            out.append(dict(id=next_id, race=race, cls=HERO, sex=sex, outfit=0,
                            items=[x[0] for x in items], disp=[x[1] for x in items], inv=[x[2] for x in items],
                            src_cls=src_cls))
            next_id += 1
    return out


# ---------------------------------------------------------------- DBC writer
def write_dbc(path, fmt, rows, strings=b'\0'):
    rs = struct.calcsize('<' + fmt)
    with open(path, 'wb') as f:
        f.write(b'WDBC' + struct.pack('<4I', len(rows), len(fmt), rs, len(strings)))
        for r in rows:
            f.write(struct.pack('<' + fmt, *r))
        f.write(strings)


def parse_chrclasses_sql(path):
    s = open(path).read()
    cols = [c.strip() for c in re.search(r'insert into main\.ChrClasses \(([^)]*)\)', s).group(1).split(',')]
    body = s.split('values', 1)[1]
    rows = []
    for m in re.finditer(r"\(((?:[^()']|'(?:[^']|'')*')*)\)", body):
        vals = re.findall(r"'((?:[^']|'')*)'|(-?\d+)", m.group(1))
        rows.append([v[0].replace("''", "'") if v[1] == '' else int(v[1]) for v in vals])
    return cols, rows


def chrclasses_dbc(cols, rows, path):
    strings = bytearray(b'\0')
    offs = {'': 0}
    def so(t):
        if t not in offs:
            offs[t] = len(strings)
            strings.extend(t.encode() + b'\0')
        return offs[t]
    packed = []
    for r in sorted(rows, key=lambda r: r[0]):
        packed.append([so(v) if isinstance(v, str) else v for v in r])
    write_dbc(path, 'I' * len(cols), packed, bytes(strings))


def append_hero_chrclasses(base, out):
    b = open(base, 'rb').read()
    n, fc, rs, ss = struct.unpack('<4I', b[4:20])
    assert fc == 60 and rs == 240, (fc, rs)
    data, strings = b[20:20 + n * rs], bytearray(b[20 + n * rs:])
    rows = [list(struct.unpack('<60I', data[i * rs:(i + 1) * rs])) for i in range(n)]
    rows = [r for r in rows if r[0] != HERO]
    hero = list(next(r for r in rows if r[0] == 2))
    def add(t):
        off = len(strings)
        strings.extend(t.encode() + b'\0')
        return off
    name = add('Hero')
    hero[0] = HERO
    for i in (4, 21, 38):          # name, name_female, name_male (enUS slot)
        hero[i] = name
    hero[55] = add('HERO')         # filename / class token
    hero[2] = HERO_DISPLAY_POWER   # display_power: mana
    hero[56] = 0                   # spell_class_set: none, Hero draws from every class
    hero[58] = 0                   # cinematic: race intro
    hero[59] = 0                   # expansion
    rows = sorted(rows + [hero], key=lambda r: r[0])
    write_dbc(out, 'I' * 60, rows, bytes(strings))


def hero_chrclasses_row(cols, rows):
    pal = dict(zip(cols, next(r for r in rows if r[0] == 2)))
    row = dict(pal)
    row['id'] = HERO
    for c in cols:
        if c.startswith(('name_lang_en_gb', 'name_female_lang_en_gb', 'name_male_lang_en_gb')):
            row[c] = 'Hero'
    row['filename'] = 'HERO'
    row['display_power'] = HERO_DISPLAY_POWER
    row['spell_class_set'] = 0          # no class spell family: Hero draws spells from every class
    row['cinematic_sequence_id'] = 0    # race intro, like the other non-DK classes
    row['required_expansion'] = 0
    return [row[c] for c in cols]


def sqlv(v):
    if isinstance(v, str):
        return "'" + v.replace("'", "''") + "'"
    if isinstance(v, float):
        return repr(round(v, 7))
    return str(v)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--client-dbc')
    ap.add_argument('--base-chrclasses-dbc', help='ChrClasses.dbc currently shipped in patch-n; Hero is appended to it '
                    '(copying its Paladin row) so the other classes stay byte-identical. Without it the DBC is rebuilt '
                    'from dmls/required/ChrClasses.sql.')
    ap.add_argument('--chrclasses-sql', default=os.path.join(HERE, '..', 'patchgenerator', 'dmls', 'required', 'ChrClasses.sql'))
    a = ap.parse_args()

    rows, stats = hero_stats()
    gt = gt_values()
    outfit_rows, outfit_strings = read_outfits()
    outfits = hero_outfits(outfit_rows)
    cols, crows = parse_chrclasses_sql(a.chrclasses_sql)
    crows = [r for r in crows if r[0] != HERO]
    hero_row = hero_chrclasses_row(cols, crows)
    pci = {(int(r[0]), int(r[1])): r for r in tsv('playercreateinfo.tsv')}
    acts = tsv('playercreateinfo_action.tsv')

    # ------------------------------------------------ server SQL
    L = ['-- Hero class (class ID 10) for Turoran Classless. GENERATED by apps/hero/gen_hero.py; edit the generator.',
         '-- Server side only: the client needs the matching patch-n DBCs (V023__HeroClass.sql + gen_hero.py --client-dbc).',
         '-- Idempotent: safe to re-run.', '']
    L.append('-- ChrClasses.dbc override row (server). DisplayPower 0 = POWER_MANA (gauntlet-design.md section 12);')
    L.append('-- mod-classless OnPlayerHasActivePowerType() keeps rage/energy/runic/focus active for all classes.')
    L.append('DELETE FROM `chrclasses_dbc` WHERE `ID` = 10;')
    L.append("INSERT INTO `chrclasses_dbc` (`ID`,`Field01`,`DisplayPower`,`PetNameToken`,`Name_Lang_enUS`,`Name_Lang_Mask`,"
             "`Name_Female_Lang_enUS`,`Name_Female_Lang_Mask`,`Name_Male_Lang_enUS`,`Name_Male_Lang_Mask`,`Filename`,"
             "`SpellClassSet`,`Flags`,`CinematicSequenceID`,`Required_Expansion`) VALUES "
             "(10,0,%d,0,'Hero',16712190,'Hero',16712190,'Hero',16712190,'HERO',0,58,0,0);" % HERO_DISPLAY_POWER)
    L.append('')
    L.append('-- CharStartOutfit.dbc override rows (server gives these items at creation).')
    L.append('DELETE FROM `charstartoutfit_dbc` WHERE `ClassID` = 10;')
    cn = ['`ID`', '`RaceID`', '`ClassID`', '`SexID`', '`OutfitID`'] + [f'`ItemID_{i}`' for i in range(1, 25)] + \
         [f'`DisplayItemID_{i}`' for i in range(1, 25)] + [f'`InventoryType_{i}`' for i in range(1, 25)]
    vals = []
    for o in outfits:
        vals.append('(' + ','.join(map(str, [o['id'], o['race'], o['cls'], o['sex'], o['outfit']] + o['items'] + o['disp'] + o['inv'])) + ')')
    L.append(f"INSERT INTO `charstartoutfit_dbc` ({','.join(cn)}) VALUES\n" + ',\n'.join(vals) + ';')
    L.append('')
    L.append('-- Base stats: per-stat mean of the 9 non-DK classes, scaled to the Paladin/Druid average total.')
    L.append('-- BaseHP/BaseMana follow the classless convention (Warrior HP, Mage mana for every class).')
    L.append('DELETE FROM `player_class_stats` WHERE `Class` = 10;')
    vals = [f"(10,{lvl},{hp},{mana},{s[0]},{s[1]},{s[2]},{s[3]},{s[4]})" for lvl, (hp, mana, s, _, _) in sorted(stats.items())]
    L.append('INSERT INTO `player_class_stats` (`Class`,`Level`,`BaseHP`,`BaseMana`,`Strength`,`Agility`,`Stamina`,`Intellect`,`Spirit`) VALUES\n' + ',\n'.join(vals) + ';')
    L.append('')
    L.append('-- Combat/regen tables: class 10 rows = mean of Paladin and Druid (the stock rows for slot 10 are placeholders).')
    for t in GT_PER_LEVEL:
        L.append(f'DELETE FROM `{t}` WHERE `ID` BETWEEN 900 AND 999;')
        L.append(f'INSERT INTO `{t}` (`ID`,`Data`) VALUES ' + ','.join(f'({900 + lvl - 1},{sqlv(gt[t][lvl])})' for lvl in range(1, 101)) + ';')
    for t in GT_BASE:
        L.append(f'DELETE FROM `{t}` WHERE `ID` = 9;')
        L.append(f'INSERT INTO `{t}` (`ID`,`Data`) VALUES (9,{sqlv(gt[t])});')
    b = gt['_scalar_base']
    L.append(f'DELETE FROM `gtoctclasscombatratingscalar_dbc` WHERE `ID` BETWEEN {9 * 32 + b} AND {9 * 32 + 31 + b};')
    L.append('INSERT INTO `gtoctclasscombatratingscalar_dbc` (`ID`,`Data`) VALUES ' +
             ','.join(f'({9 * 32 + r + b},{sqlv(v)})' for r, v in sorted(gt['gtoctclasscombatratingscalar_dbc'].items())) + ';')
    L.append('')
    L.append('-- Creation: every playable race, starting at the race\'s Warrior start (Blood Elf: Paladin start).')
    L.append('DELETE FROM `playercreateinfo` WHERE `class` = 10;')
    vals = []
    for race in PLAYABLE_RACES:
        src = pci.get((race, 1)) or pci[(race, 2)]
        vals.append('(' + ','.join([str(race), '10'] + src[2:]) + ')')
    L.append('INSERT INTO `playercreateinfo` (`race`,`class`,`map`,`zone`,`position_x`,`position_y`,`position_z`,`orientation`) VALUES\n' + ',\n'.join(vals) + ';')
    L.append('DELETE FROM `playercreateinfo_action` WHERE `class` = 10;')
    vals = []
    for race in PLAYABLE_RACES:
        vals.append(f'({race},10,0,6603,0)')                     # Auto Attack on slot 1
        racial = [r for r in acts if int(r[0]) == race and int(r[1]) in (1, 2) and int(r[3]) not in (6603, 78, 21084, 635, 59752 if race != 1 else -1)]
        seen = set()
        btn = 1
        for r in racial:
            if r[3] in seen:
                continue
            seen.add(r[3])
            vals.append(f'({race},10,{btn},{r[3]},{r[4]})')
            btn += 1
    L.append('INSERT INTO `playercreateinfo_action` (`race`,`class`,`button`,`action`,`type`) VALUES ' + ','.join(vals) + ';')
    L.append('')
    srv = os.path.join(HERE, '..', '..', 'data', 'sql', 'db-world', 'hero_class.sql')
    open(srv, 'w').write('\n'.join(L) + '\n')

    # ------------------------------------------------ Flyway migration for the client sqlite
    M = ['-- V023: Hero class (class ID 10) on the client: ChrClasses, CharBaseInfo, CharStartOutfit.',
         '-- GENERATED by apps/hero/gen_hero.py. gt* tables are not in wow_dbc; gen_hero.py --client-dbc builds them.',
         '-- After applying, export with: export-required-sql.py --table CharBaseInfo --table CharStartOutfit', '']
    M.append('delete from main.ChrClasses where id = 10;')
    M.append(f"insert into main.ChrClasses ({', '.join(cols)}) values ({', '.join(sqlv(v) for v in hero_row)});")
    M.append('delete from main.CharBaseInfo where class_id = 10;')
    M.append('insert into main.CharBaseInfo (race_id, class_id) values ' + ', '.join(f'({r}, 10)' for r in PLAYABLE_RACES) + ';')
    M.append('delete from main.CharStartOutfit where class_id = 10;')
    oc = ['id', 'race_id', 'class_id', 'sex_id', 'outfit_id'] + [f'item_id_{i}' for i in range(24)] + \
         [f'display_item_id_{i}' for i in range(24)] + [f'inventory_type_{i}' for i in range(24)]
    M.append(f"insert into main.CharStartOutfit ({', '.join(oc)}) values\n" + ',\n'.join(
        '(' + ', '.join(map(str, [o['id'], o['race'], o['cls'], o['sex'], o['outfit']] + o['items'] + o['disp'] + o['inv'])) + ')' for o in outfits) + ';')
    mig = os.path.join(HERE, '..', 'patchgenerator', 'dmls', 'migrations', 'V023__HeroClass.sql')
    open(mig, 'w').write('\n'.join(M) + '\n')

    # ------------------------------------------------ client DBCs
    if a.client_dbc:
        os.makedirs(a.client_dbc, exist_ok=True)
        if a.base_chrclasses_dbc:
            append_hero_chrclasses(a.base_chrclasses_dbc, os.path.join(a.client_dbc, 'ChrClasses.dbc'))
        else:
            chrclasses_dbc(cols, crows + [hero_row], os.path.join(a.client_dbc, 'ChrClasses.dbc'))
        cbi = open(os.path.join(INP, 'CharBaseInfo.dbc'), 'rb').read()
        n = struct.unpack('<I', cbi[4:8])[0]
        pairs = [tuple(cbi[20 + i * 2:22 + i * 2]) for i in range(n) if cbi[21 + i * 2] != HERO]
        pairs += [(r, HERO) for r in PLAYABLE_RACES]
        write_dbc(os.path.join(a.client_dbc, 'CharBaseInfo.dbc'), 'BB', sorted(pairs))
        allrows = [r for r in outfit_rows if r['cls'] != HERO] + outfits
        write_dbc(os.path.join(a.client_dbc, 'CharStartOutfit.dbc'), 'I4B' + '24i' * 3,
                  [[r['id'], r['race'], r['cls'], r['sex'], r['outfit']] + r['items'] + r['disp'] + r['inv'] for r in allrows],
                  outfit_strings)
        for t in GT_PER_LEVEL + GT_BASE + ['gtoctclasscombatratingscalar_dbc']:
            v = {int(x): float(y) for x, y in tsv(t + '.tsv')}
            if t in GT_PER_LEVEL:
                for lvl in range(1, 101):
                    v[900 + lvl - 1] = gt[t][lvl]
            elif t in GT_BASE:
                v[9] = gt[t]
            else:
                for r, val in gt[t].items():
                    v[9 * 32 + r + b] = val
            ids = sorted(v)
            if t == 'gtoctclasscombatratingscalar_dbc':   # client file has (ID, value) records
                write_dbc(os.path.join(a.client_dbc, GT_FILES[t]), 'If', [(i, v[i]) for i in ids])
            else:
                write_dbc(os.path.join(a.client_dbc, GT_FILES[t]), 'f', [(v[i],) for i in ids])

    # ------------------------------------------------ review doc
    D = ['# Hero class numbers (generated by gen_hero.py)', '',
         'Primary stats per level = mean of each stat over the 9 non-DK classes, scaled so the five-stat total equals',
         'the average of the Paladin and Druid totals at that level (largest-remainder rounding).',
         'BaseHP/BaseMana: same curves every classless class already uses (Warrior HP, Mage mana).', '',
         '| Level | Str | Agi | Sta | Int | Spi | Hero total | 9-class mean total | Paladin | Druid | Warrior | Mage | BaseHP | BaseMana |',
         '|---|---|---|---|---|---|---|---|---|---|---|---|---|---|']
    for lvl in (1, 10, 20, 30, 40, 50, 60, 70, 80):
        hp, mana, s, tgt, avg = stats[lvl]
        D.append(f"| {lvl} | {' | '.join(map(str, s))} | {sum(s)} | {round(sum(avg), 1)} | "
                 f"{sum(rows[(2, lvl)][2:])} | {sum(rows[(11, lvl)][2:])} | {sum(rows[(1, lvl)][2:])} | {sum(rows[(8, lvl)][2:])} | {hp} | {mana} |")
    D += ['', 'Combat/regen ratios (class-10 rows) = mean of Paladin and Druid:', '',
          '| Table | L1 | L60 | L80 | Paladin L80 | Druid L80 |', '|---|---|---|---|---|---|']
    for t in GT_PER_LEVEL:
        v = {int(x): float(y) for x, y in tsv(t + '.tsv')}
        D.append(f"| {t} | {gt[t][1]:.6f} | {gt[t][60]:.6f} | {gt[t][80]:.6f} | {v[179]:.6f} | {v[1079]:.6f} |")
    for t in GT_BASE:
        D.append(f"| {t} | {gt[t]:.5f} (flat) | | | | |")
    D += ['', 'Starting outfits (class 10):', '', '| Race | Sex | Items (item:invType) | Armour source |', '|---|---|---|---|']
    for o in outfits:
        its = ', '.join(f"{i}:{t}" for i, t in zip(o['items'], o['inv']) if i > 0)
        D.append(f"| {RACE_NAMES[o['race']]} | {'M' if o['sex'] == 0 else 'F'} | {its} | {CLASS_NAMES[o['src_cls']]} |")
    open(os.path.join(HERE, 'hero_numbers.md'), 'w').write('\n'.join(D) + '\n')
    print('wrote', srv, mig, 'hero_numbers.md', a.client_dbc or '')


if __name__ == '__main__':
    main()
