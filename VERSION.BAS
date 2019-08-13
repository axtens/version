100 tilde="~"
110 dquote=chr(34)
120 groupname=""
130 editor=""
140 language=""
150 copyright=""
160 extension=""
170 fname=""
180 fext=""
190 if argc () < 1
200 then
210 print "Version <filename> [<groupname>] [/NOEDIT]"
220 end
230 end if
240 groupflag = 0
250 slashflag = 0
260 slashcode = ""
270 if argc () > 1
280 then
290 if left(argv (2),1)="/"
300 then
310 groupflag = 0
320 slashflag = 1
330 slashcode = argv (2)
340 else
350 groupflag = 1
360 groupname = argv (2)
370 if argc () > 2
380 then
390 if left( argv (3),1) = "/"
400 then
410 slashflag = 1
420 slashcode = argv (3)
430 end if
440 end if
450 end if
460 end if
470 noedit = 0
480 if slashflag=1
490 then
500 if mid(slashcode,2,1) = "n" or mid(slashcode,2,1)="N"
510 then
520 noedit = 1
530 end if
540 end if
550 gosub 2160
560 ucaserec = argv (1)
570 gosub 2580
580 filename = ucaserec
590 j = instr(filename,".")
600 if j <> 0
610 then
620 fname = left(filename,j-1)
630 fext = mid(filename,j)
640 else
650 if extension=""
660 then
670 print "Need extension on filename"
680 end
690 else
700 fname=filename
710 fext=extension
720 end if
730 end if
740 srcname = fname + fext
750 bakname = fname + ".BAK"
760 if editor = ""
770 then
780 print "'editor' not set in VERSION.INI"
790 end
800 end if
810 if copyright = ""
820 then
830 copyright="(c) Copyright Bruce M. Axtens, 1993"
840 end if
850 if groupname = ""
860 then
870 grplog = fname + ".VLG"
880 grpzip = fname + ".ZIP"
890 groupflag = 0
900 else
910 ucaserec = groupname
920 gosub 2580
930 groupname = ucaserec
940 grplog = left(groupname,8)+".VLG"
950 grpzip = left(groupname,8)+".ZIP"
960 groupflag = 1
970 end if
980 if noedit = 0 then shell editor+" "+srcname
990 if access(bakname) = 0
1000 then
1010 print "Could not open ";bakname;". Assuming no changes done."
1020 end
1030 end if
1040 print "Storing previous version details of ";srcname;" in ";grplog
1050 print "Storing previous version of ";srcname;" in ";grpzip
1060 gosub 2360
1070 execute "mkdir "+dirname
1080 open #1,"r",bakname
1090 open #2,"w",dirname+"\"+srcname
1100 REM
1110 if not eof(1)
1120 then
1130 line input #1, r
1140 print #2,r
1150 goto 1100
1160 end if
1170 close #1
1180 close #2
1190 execute "kill "+bakname
1200 if access(grplog)=0
1210 then
1220 open #1,"w",grplog
1230 close #1
1240 end if
1250 print "Changes: ";
1260 changes=""
1270 input changes
1280 outline=srcname+tilde+datestr+tilde+timestr+tilde+dirname+tilde+changes
1290 shell "echo "+outline+">>"+grplog
1300 shell "pkzip -m -r -P "+grpzip+" "+dirname+"\*.* >nul"
1310 REM
1320 if groupflag = 1
1330 then
1340 vername = left(groupname,8)
1350 else
1360 vername = fname
1370 end if
1380 vernamefile = vername + ".VER"
1390 if access(vernamefile)=0
1400 then
1410 open #1, "w", vernamefile
1420 print #1, "*,1,0,0"
1430 close #1
1440 end if
1450 print "Storing version details in ";vernamefile
1460 open #1,"r",vernamefile
1470 line input #1, verrec
1480 mark=parse(verrec,"","",",")
1490 majver=parse(verrec,"","",",")
1500 minver=parse(verrec,"","",",")
1510 subver=verrec
1520 'input #1,mark;majver;minver;subver
1530 close #1
1540 subver=0
1550 minver=minver+1
1560 if minver>99
1570 then
1580 majver=majver+1
1590 minver=0
1600 end if
1610 open #1,"w",vernamefile
1620 comma=","
1630 'language = environ("VLANG")
1640 if language <> ""
1650 then
1660 if language = "XBASE"
1670 then
1680 gosub 1840
1690 end if
1700 if language = "CLIPPER"
1710 then
1720 gosub 1950
1730 end if
1740 if language = "BASIC"
1750 then
1760 gosub 2060
1770 end if
1780 else
1790 gosub 2060
1800 end if
1810 close #1
1820 if language = "XBASE" then shell "copy "+vernamefile+" version.prg"
1830 end
1840 REM
1850 mark="*"
1860 print #1,mark;comma;majver;comma;minver;comma;subver
1870 print #1,"PRIV nMajVer, nMinVer, cProgName, cEditDate, cFlagWave"
1880 print #1,"cProgName = UPPER(["+vername+"])"
1890 print #1,"nMajVer   = ";majver
1900 print #1,"nMinVer   = ";minver
1910 print #1,"cEditDate = [";date();"]"
1920 print #1,"cFlagWave = cProgName+[ v";majver;".";minver;" (";date();")]"
1930 print #1,"?? cProgName+";dquote;" v";majver;".";minver;space(1);copyright;dquote
1940 return
1950 REM
1960 mark="*"
1970 print #1,mark;comma;majver;comma;minver;comma;subver
1980 print #1,"PUBLIC nMajVer := ";majver
1990 print #1,"PUBLIC nMinVer := ";minver
2000 print #1,"PUBLIC cProgName := '";vername;"'"
2010 print #1,"PUBLIC cVersion  := '";majver;".";minver;"'"
2020 print #1,"PUBLIC cCopyright:= '";copyright;"'"
2030 print #1,"PUBLIC cProgVer  := cProgName+[ V]+cVersion"
2040 print #1,"QQOUT(cProgVer+space(1)+cCopyright)"
2050 return
2060 REM
2070 mark = "'"
2080 print #1,"1 ";mark;comma;majver;comma;minver;comma;subver
2090 print #1,"2 ";"cProgName = ";dquote;vername;dquote
2100 print #1,"3 ";"nMajVer   = ";majver
2110 print #1,"4 ";"nMinVer   = ";minver
2120 print #1,"6 '";"cEditDate = ";dquote;date();dquote
2130 print #1,"7 '";"cFlagWave = cProgName+";dquote;" v";majver;".";minver;" (";date();")";dquote
2140 print #1,"8 print ";"cProgName+";dquote;" v";majver;".";minver;space(1);copyright;dquote
2150 return
2160 REM
2170 if access("VERSION.INI") = 0
2180 then
2190 return
2200 end if
2210 open #1, "r", "VERSION.INI"
2220 if not eof(1)
2230 then
2240 line input #1, rec
2250 x=instr(rec,tilde)
2260 if x <> 0
2270 then
2280 rec = strovr(rec,x,dquote)
2290 goto 2250
2300 end if
2310 execute rec
2320 goto 2220
2330 end if
2340 close #1
2350 return
2360 REM
2370 n="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
2380 '
2390 datestr=date()
2400 timestr=time()
2410 '
2420 day=mid(datestr,4,2)
2430 mon=left(datestr,2)
2440 yar=right(datestr,2)
2450 '
2460 hh=left(timestr,2)
2470 mm=mid(timestr,4,2)
2480 ss=right(timestr,2)
2490 '
2500 dn1=mid(n,day+1,1)
2510 dn2=mid(n,mon+1,1)
2520 dn3=mid(n,yar-80+1,1)
2530 dn4=mid(n,hh+1,1)
2540 '
2550 dirname = dn1+dn2+dn3+dn4+mm+ss
2560 return
2570 '
2580 REM
2590 ucaselen=len(ucaserec)
2600 for ui=1 to ucaselen
2610 c=mid(ucaserec,ui,1)
2620 if c>="a" and c<="z"
2630 then
2640 ucaserec=strovr(ucaserec,ui,chr( asc(c) - 32))
2650 end if
2660 next ui
2670 return
merge version.VER 
link version
quit
