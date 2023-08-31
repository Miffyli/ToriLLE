-- http://lua-users.org/wiki/OsLibraryTutorial
-- Enabled Commands:
-- time = os.time([table t])
-- date = os.date([string format [, time t])
-- time = os.difftime(time t1, time t1)
-- temp = os.tempname()

now = os.date("*t")
echo(string.format("%s:%s:%s", now.hour, now.min, now.sec))

