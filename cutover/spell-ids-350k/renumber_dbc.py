#!/usr/bin/env python3
"""Renumber custom spells 360001-360016 -> 350011-350026 in WotLK 3.3.5 DBCs (in place on copies).
Spell.dbc field 0 (ID); SkillLineAbility.dbc field 2 (Spell); Talent.dbc fields 4-12 (SpellRank[9]).
Idempotent: only rewrites values still in the old range."""
import struct,sys,os
MAP={o:o-9990 for o in range(360001,360017)}
FIELDS={'Spell.dbc':[0],'SkillLineAbility.dbc':[2],'Talent.dbc':list(range(4,13))}
src,dst=sys.argv[1],sys.argv[2]; os.makedirs(dst,exist_ok=True)
for fn,cols in FIELDS.items():
    d=bytearray(open(os.path.join(src,fn),'rb').read()); n,f,rs,ss=struct.unpack('<4I',d[4:20]); ch=0
    for i in range(n):
        for c in cols:
            o=20+i*rs+c*4; v=struct.unpack_from('<I',d,o)[0]
            if v in MAP: struct.pack_into('<I',d,o,MAP[v]); ch+=1
    open(os.path.join(dst,fn),'wb').write(d); print(fn,'changed',ch)
