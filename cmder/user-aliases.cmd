;= @echo off
;= rem Call DOSKEY and use this file as the macrofile
;= %SystemRoot%\system32\doskey /listsize=1000 /macrofile=%0%
;= rem In batch mode, jump to the end of the file
;= goto:eof
;= Add aliases below here
e.=explorer .
gl=git log --oneline --all --graph --decorate  $*
ls=ls --show-control-chars -F --color $*
pwd=cd
clear=cls
history=cat "%CMDER_ROOT%\config\.history"
unalias=alias /d $1
vi=vim $*
cmderr=cd /d "%CMDER_ROOT%"
ga=git add $*
gs=git status $*
gc=git commit -m $*
gps=git push origin master
gpl=git pull origin master
ll=ls -alsF --color $*
va=svn add --force $*
vs=svn status $*
vc=svn commit -m $*
vu=svn update $*
w=cd /d d:\wings-dev\OneWings
ws=cd /d d:\wings-dev\OneWingsSupFiles
