# Daily worldserver restart (both realms)

Restarts each worldserver at **07:00 America/Chicago** with a 5-minute in-game countdown, so a slow memory leak can't build up across days. It runs the same way on Standard (.100) and Roguelike (.101).

**No SOAP or RA:** both are disabled on the realms. The restart is requested through a trigger file that an ALE/Eluna script polls, so no credentials are involved and none belong in this folder.

## How it works
| Time (CT) | Piece | What it does |
|---|---|---|
| 06:55:00 | `wow-daily-restart-trigger.timer` → `wow-daily-restart.sh trigger` | If the unit is active, atomically writes `"300 <epoch>"` to the trigger file. |
| within 10 s | `DailyRestart.lua` (ALE, `CreateLuaEvent` every 10 s) | Reads and deletes the trigger, broadcasts the warning, runs `.server restart 300`. Triggers older than 15 min are ignored. `cancel <epoch>` runs `.server restart cancel`. |
| ~07:00 | worldserver | Exits after the countdown; systemd starts it again (`Restart=always` on Standard's `worldserver`, `Restart=on-failure` on `wow-roguelike-worldserver`, both restart after the restart exit). |
| 07:10:00 | `wow-daily-restart-watchdog.timer` → `wow-daily-restart.sh watchdog` | Removes any leftover trigger. If the unit's `ExecMainStartTimestamp` is before 06:50 CT today, forces `systemctl restart` (SIGTERM = graceful save). |

The timers use `OnCalendar=… America/Chicago`, so they follow CST/CDT whatever the guest's TZ is (.101 runs in UTC).

## Files
- `DailyRestart.lua.tmpl`, `wow-daily-restart.sh.tmpl`: templates with `@TRIGGER@` / `@UNIT@` placeholders.
- `wow-daily-restart-{trigger,watchdog}.{service,timer}`: identical on both realms.
- `realms/{standard,roguelike}.env`: per-realm `TRIGGER`, `UNIT` and `LUA_DIR`.
- `render.sh <realm.env> <outdir>`: renders one realm's files. It doesn't install anything.

## Install (as root on the realm VM)
```bash
cd server-ops/daily-restart
./render.sh realms/standard.env /tmp/dr        # or realms/roguelike.env
. realms/standard.env
install -m 644 /tmp/dr/DailyRestart.lua "$LUA_DIR/DailyRestart.lua"
install -m 755 /tmp/dr/wow-daily-restart.sh /usr/local/sbin/wow-daily-restart.sh
install -m 644 /tmp/dr/wow-daily-restart-*.service /tmp/dr/wow-daily-restart-*.timer /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now wow-daily-restart-trigger.timer wow-daily-restart-watchdog.timer
```
The Lua is picked up on the next worldserver start or `.reload ale`. Back up any file you replace as `.bak-YYYYMMDD-HHMM` first, and disable any old restart cron (Standard's old 08:00 cron is disabled; backup in `/root/crontab.bak-20261029-2338`).

## Check / operate
```bash
systemctl list-timers 'wow-daily-restart-*'
journalctl -t wow-daily-restart --since today
/usr/local/sbin/wow-daily-restart.sh trigger                   # restart now with the 5-min countdown
echo "cancel $(date +%s)" > "$TRIGGER"                         # cancel a pending countdown (within 10 s of a trigger)
```
The worldserver log shows `[DailyRestart] server restart 300 issued`.
