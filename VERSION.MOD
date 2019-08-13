MODULE VERSION;
    FROM System IMPORT GetArg, Terminate;
    FROM ASCII IMPORT NUL;
    FROM Strings IMPORT Copy, Length, Assign, Append;
    FROM Dictionary IMPORT DictCreate, DictLoad, DictSave, nDictUsed, DictInsert, DictRetrieve;
    FROM XString IMPORT UpperCase;
    FROM FileSpec IMPORT ParseFileSpec, HasExt;
    FROM Terminal IMPORT ReadLine, KeyPressed, Read;
    FROM InOut IMPORT WriteString, WriteLine, WriteLn, WriteCard;
    FROM SHELL IMPORT Shell;
    FROM DATEDIR IMPORT DateDir;
    FROM XDOS IMPORT Exists;
    FROM Directories IMPORT MkDir, RmDir;
    FROM Files IMPORT Seek, SEEKEND, Create, Rename, Open, Write, WRITE, NORMAL, Close, Delete;
    FROM DATETIME IMPORT GetDate, GetTime;
    FROM SYSTEM IMPORT ADR;
    FROM DEBUG IMPORT cDebugNumWidth, SetDebug, DebugS, DebugL;
    FROM FINDREPL IMPORT FindRepl;

    CONST
        xDQUOTE = '"';
        xSLASH  = '/';
        xSPACE  = 40C;
        xDOT    = ".";
        xBACKSLASH = "\";
        nCOMMENT    =  80;
        nFILENAME   =   8;
        nFILESPEC   =  12;
        nPATHSPEC   =  64;
        nFILEEXT    =   3;
        nCOMMAND    = 127;

    TYPE
        tCOMMENT   = ARRAY [ 0 .. nCOMMENT -1 ] OF CHAR;
        tFILENAME  = ARRAY [ 0 .. nFILENAME -1 ] OF CHAR;
        tFILESPEC  = ARRAY [ 0 .. nFILESPEC -1 ] OF CHAR;
        tPATHSPEC  = ARRAY [ 0 .. nPATHSPEC -1 ] OF CHAR;
        tFILEEXT   = ARRAY [ 0 .. nFILEEXT ] OF CHAR;
        tCOMMAND   = ARRAY [ 0 .. nCOMMAND -1 ] OF CHAR;

        rChange = RECORD
                    sFileSpec  : tFILESPEC;
                    sDate      : tFILENAME;
                    sTime      : tFILENAME;
                    sDirName   : tFILENAME;
                    sComments  : tCOMMENT;
                  END;


    VAR

        lcLength : LONGCARD;

        rChgRec : rChange;

        iBuff : INTEGER;

        sLineNo    : ARRAY [0..5] OF CHAR;
        sDateDir   : tFILENAME;
        sGroupName : tFILENAME;
        sEditor    : tFILESPEC;
        sLanguage  : tFILENAME;
        sCopyRight : ARRAY [0..29] OF CHAR;
        sCmmnts    : tCOMMENT;
        sShellCmd   : tPATHSPEC;
        sDestPath   : tPATHSPEC;
        sGroupLog   : tPATHSPEC;
        sGroupArc   : tPATHSPEC;
        sSourceName : tPATHSPEC;
        sBackName   : tPATHSPEC;
        sDeltaName  : tPATHSPEC;
        sPath       : tPATHSPEC;
        sFileExt    : tFILEEXT;
        sArchiveExt : tFILEEXT;
        sExt        : tFILEEXT;
        sExtension  : tFILEEXT;
        sName       : tFILESPEC;
        sFileName   : tFILESPEC;
        sArchiveCmd : tCOMMAND;
        sParam      : tCOMMAND;

        xDrive  : CHAR;
        xChar   : CHAR;
        xSlash  : CHAR;


        bNoEdit              : BOOLEAN;
        bCommandLineComments : BOOLEAN;

        cRetCode   : CARDINAL;
        cCnt       : CARDINAL;

    PROCEDURE Help;
        BEGIN
        END Help;

    BEGIN

        GetArg( sFileName, cCnt);
        IF cCnt = 0 THEN
            Help;
            Terminate(0)
        END;
        UpperCase( sFileName);


        bNoEdit := FALSE;
        bCommandLineComments := FALSE;
        xSlash := NUL;
        sGroupName := '';
        sCmmnts := '';

        LOOP
            GetArg( sParam, cCnt);
            IF cCnt = 0 THEN
                EXIT
            END;
            IF sParam[0] = xSLASH THEN
                xSlash := CAP( sParam[1]);
                CASE xSlash OF
                    "N" : bNoEdit := TRUE;
                    |
                    "G" : Copy( sParam, 2, Length( sParam ), sGroupName );
                    |
                    "C" : bCommandLineComments := TRUE;
                          Copy( sParam, 2, Length( sParam ), sCmmnts );
                    |
                    "L" : Copy( sParam, 2, Length( sParam ), sLineNo );
                    |
                    ELSE (* nothing *)
                END;
            END
        END;

        WITH rChgRec DO
            sComments := '';
            sDate := '';
            sTime := '';
            sDirName := '';
            sFileSpec := '';
        END;

        DictCreate();
        DictLoad( "VERSION.SET");

        ParseFileSpec( sFileName, xDrive, sPath, sName, sExt);

        IF HasExt( sFileName) THEN
            Assign(sName,sFileName);
            Assign(sExt,sExtension);
        ELSE
            DictRetrieve("EXTENSION",sExtension);

            IF sExtension[0] = NUL THEN
                WriteLine("Need extension.");
                Terminate(0)
            ELSE
                sFileName := sName;
            END;
        END;

        Assign(sFileName,sSourceName);
        IF sExtension[0] # xDOT THEN
            Append(sSourceName,xDOT)
        END;
        Append(sSourceName,sExtension);

        Assign(sFileName,sBackName);
        Append(sBackName,".BAK");

        DictRetrieve("EDITOR",sEditor);
        IF sEditor[0]=NUL THEN
            WriteLine("Need Editor");
            Terminate(0)
        END;

        DictRetrieve("COPYRIGHT",sCopyRight);
        IF sCopyRight[0] = NUL THEN
            sCopyRight := '(c) Copyright Bruce M. Axtens, 1996.'
        END;

        DictRetrieve( "ARCHIVEEXT", sArchiveExt );
        IF sArchiveExt[0] = NUL THEN
                sArchiveExt := ".ZIP"
        END;

        IF sGroupName[0] = NUL THEN
            DictRetrieve("GROUPNAME",sGroupName);
            IF sGroupName[0] = NUL THEN
                Assign(sFileName,sGroupName);
            END;
        END;
        Assign(sGroupName,sGroupLog);
        Append(sGroupLog,".VLG");
        Assign(sGroupName,sGroupArc);
        Append(sGroupArc,sArchiveExt);


        Assign( sFileName, sDeltaName );
        Append( sDeltaName, ".DLT" );

        IF NOT bNoEdit THEN
            Assign(sEditor,sShellCmd);
            FindRepl( sShellCmd, "$f", sSourceName, sShellCmd );
            IF sLineNo[0] = 0C THEN
               sLineNo := "1"
            END;
            FindRepl( sShellCmd, "$n", sLineNo, sShellCmd );
            IF NOT Shell(sShellCmd, cRetCode) THEN
                WriteString("DOS Error: ");
                WriteCard(cRetCode,2);
                WriteLn
            END;
        END;

        IF NOT Exists(sBackName) THEN
            WriteString("Could not open ");
            WriteString(sBackName);
            WriteLine(". Assuming no changes done.");
            Terminate(0)
        END;

        WriteString("Storing previous version of ");
        WriteString(sSourceName);
        WriteString(" in ");
        WriteLine(sGroupArc);

        sShellCmd := 'DELTA ';
        Append( sShellCmd, sName );
        Append( sShellCmd, xSPACE );
        IF sExtension[0] # xDOT THEN
            Append( sShellCmd, xDOT )
        END;
        Append( sShellCmd, sExtension );

        IF NOT Shell( sShellCmd, cRetCode ) THEN
            WriteString("DOS Error: ");
            WriteCard(cRetCode,2);
            WriteLn
        END;

        Delete( sBackName );

        DateDir( sDateDir);

        (* MkDir( sDateDir); *)

        (* Assign(sDateDir,sDestPath); *)

        sDestPath := '';
        (* Append(sDestPath,xBACKSLASH); *)
        Append(sDestPath,sDateDir);
        Append(sDestPath,".DLT" ); (* sDeltaName);*)

        Rename( sDeltaName, sDestPath);

        IF NOT Exists( sGroupLog) THEN
            Create( iBuff, sGroupLog, NORMAL);
        ELSE
            Open( iBuff, sGroupLog, WRITE);
            Seek( iBuff, SEEKEND, lcLength)
        END;

        WHILE KeyPressed() DO Read( xChar) END;

        IF NOT bCommandLineComments THEN
            WriteString("CHANGES> ");
            ReadLine(sCmmnts)
        END;

        WITH rChgRec DO
            sComments := sCmmnts; (* Assign(sCmmnts,sComments); *)
            GetDate(sDate);
            GetTime(sTime);
            Assign( sDateDir, sDirName);
            Assign( sSourceName, sFileSpec)
        END;

        Write(iBuff,ADR(rChgRec),SIZE(rChgRec), cCnt);

        Close(iBuff);

        DictRetrieve( "ARCHIVECMD", sArchiveCmd );
        IF sArchiveCmd[0] = NUL THEN
                sArchiveCmd := "PKZIP -m"
        END;

        Append( sArchiveCmd, xSPACE );
        Append( sArchiveCmd, sGroupArc);
        Append( sArchiveCmd, xSPACE);
        (* Append( sArchiveCmd, sDateDir);
        Append( sArchiveCmd, "\*.*"); *)
        Append( sArchiveCmd, sDateDir );
        Append( sArchiveCmd, ".DLT" );

        IF NOT Shell( sArchiveCmd, cRetCode) THEN
            WriteString("DOS Error: ");
            WriteCard(cRetCode,2);
            WriteLn
        END;

        (* RmDir( sDateDir); *)
END VERSION.

