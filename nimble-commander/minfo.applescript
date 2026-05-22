on open fileList
    set filePath to POSIX path of (item 1 of fileList)
    set mi to "/opt/homebrew/bin/mediainfo"
    set q to quoted form of filePath

    -- Папка: показываем размер и счётчики
    try
        do shell script "test -d " & q
        set fName to do shell script "basename " & q
        set sizeStr to do shell script "du -sh " & q & " 2>/dev/null | cut -f1"
        set fileCount to do shell script "find " & q & " -maxdepth 1 -not -name '.' -type f | wc -l | tr -d ' '"
        set dirCount to do shell script "find " & q & " -maxdepth 1 -not -name '.' -type d | wc -l | tr -d ' '"
        -- find считает саму папку как d, вычитаем 1
        set dirCount to (dirCount as integer) - 1
        set nl to return
        set tab1 to "    "
        set msg to "FOLDER" & nl
        set msg to msg & tab1 & my row("Size", sizeStr) & nl
        set msg to msg & tab1 & my row("Files", fileCount as string) & nl
        set msg to msg & tab1 & my row("Subfolders", dirCount as string) & nl
        display dialog msg with title fName buttons {"OK"} default button 1
        return
    end try

    try
        do shell script "test -f " & mi
    on error
        display alert "minfo" message "mediainfo не установлен.  brew install mediainfo" as warning
        return
    end try

    -- Одним вызовом на секцию
    set vRaw to do shell script mi & " --Inform='Video;%Format%|%Format_Profile%|%Width%|%Height%|%FrameRate%|%BitRate/String%|%ScanType%|%ColorSpace%|%BitDepth%|%Duration/String3%' " & q
    set aRaw to do shell script mi & " --Inform='Audio;%Format%|%Channel(s)/String%|%SamplingRate/String%|%BitRate/String%' " & q
    set gRaw to do shell script mi & " --Inform='General;%Format%|%FileSize/String%|%Duration/String3%|%OverallBitRate/String%' " & q
    set fName to do shell script "basename " & q

    -- Парсим видео
    set vF to my field(vRaw, 1)
    set vProf to my field(vRaw, 2)
    set vW to my field(vRaw, 3)
    set vH to my field(vRaw, 4)
    set vFps to my field(vRaw, 5)
    set vBr to my field(vRaw, 6)
    set vScan to my field(vRaw, 7)
    set vCS to my field(vRaw, 8)
    set vBd to my field(vRaw, 9)
    set vDur to my field(vRaw, 10)

    -- Парсим аудио
    set aF to my field(aRaw, 1)
    set aCh to my field(aRaw, 2)
    set aSR to my field(aRaw, 3)
    set aBr to my field(aRaw, 4)

    -- Парсим общее
    set gFmt to my field(gRaw, 1)
    set gSize to my field(gRaw, 2)
    set gDur to my field(gRaw, 3)
    set gBr to my field(gRaw, 4)

    set nl to return
    set tab1 to "    "
    set msg to ""

    -- VIDEO
    if vF is not "" then
        set codec to vF
        if vProf is not "" then set codec to codec & "  " & vProf
        set msg to msg & "VIDEO" & nl
        set msg to msg & tab1 & my row("Codec", codec) & nl
        if vW is not "" then
            set msg to msg & tab1 & my row("Resolution", vW & " × " & vH) & nl
        end if
        if vFps is not "" then
            set fps to vFps
            if vScan is not "" and vScan is not "Progressive" then
                set fps to fps & "  " & vScan
            end if
            set msg to msg & tab1 & my row("Frame rate", fps) & nl
        end if
        if vBr is not "" then
            set msg to msg & tab1 & my row("Bitrate", vBr) & nl
        end if
        if vDur is not "" then
            set msg to msg & tab1 & my row("Duration", vDur) & nl
        end if
        set colorInfo to ""
        if vCS is not "" then set colorInfo to vCS
        if vBd is not "" then
            if colorInfo is not "" then
                set colorInfo to colorInfo & "  " & vBd & "-bit"
            else
                set colorInfo to vBd & "-bit"
            end if
        end if
        if colorInfo is not "" then
            set msg to msg & tab1 & my row("Color", colorInfo) & nl
        end if
    end if

    -- AUDIO
    if aF is not "" then
        if msg is not "" then set msg to msg & nl
        set msg to msg & "AUDIO" & nl
        set msg to msg & tab1 & my row("Format", aF) & nl
        if aCh is not "" then
            set msg to msg & tab1 & my row("Channels", aCh) & nl
        end if
        if aSR is not "" then
            set msg to msg & tab1 & my row("Sample rate", aSR) & nl
        end if
        if aBr is not "" then
            set msg to msg & tab1 & my row("Bitrate", aBr) & nl
        end if
    end if

    -- FILE
    if msg is not "" then set msg to msg & nl
    set msg to msg & "FILE" & nl
    if gFmt is not "" then
        set msg to msg & tab1 & my row("Container", gFmt) & nl
    end if
    if gSize is not "" then
        set msg to msg & tab1 & my row("Size", gSize) & nl
    end if
    if gDur is not "" then
        set msg to msg & tab1 & my row("Duration", gDur) & nl
    end if
    if gBr is not "" then
        set msg to msg & tab1 & my row("Overall BR", gBr) & nl
    end if

    display dialog msg with title fName buttons {"OK"} default button 1
end open

-- Получить N-е поле из строки с разделителем |
on field(str, n)
    set oldDelim to AppleScript's text item delimiters
    set AppleScript's text item delimiters to "|"
    set parts to text items of str
    set AppleScript's text item delimiters to oldDelim
    if n > (count of parts) then return ""
    set val to item n of parts
    if val is missing value then return ""
    return val
end field

-- Форматировать строку "Label:   value" с выравниванием
on row(label, value)
    set padded to label & ":"
    repeat while (length of padded) < 13
        set padded to padded & " "
    end repeat
    return padded & " " & value
end row
