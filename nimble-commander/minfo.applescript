on open fileList
    set filePath to POSIX path of (item 1 of fileList)
    set mediainfoBin to "/opt/homebrew/bin/mediainfo"
    set q to quoted form of filePath

    try
        do shell script "test -f " & mediainfoBin
    on error
        display alert "minfo" message "mediainfo не установлен. Запусти: brew install mediainfo" as warning
        return
    end try

    set vFormat     to do shell script mediainfoBin & " --Inform='Video;%Format%' " & q
    set vProfile    to do shell script mediainfoBin & " --Inform='Video;%Format_Profile%' " & q
    set vWidth      to do shell script mediainfoBin & " --Inform='Video;%Width%' " & q
    set vHeight     to do shell script mediainfoBin & " --Inform='Video;%Height%' " & q
    set vFps        to do shell script mediainfoBin & " --Inform='Video;%FrameRate%' " & q
    set vBitrate    to do shell script mediainfoBin & " --Inform='Video;%BitRate/String%' " & q

    set aFormat     to do shell script mediainfoBin & " --Inform='Audio;%Format%' " & q
    set aChannels   to do shell script mediainfoBin & " --Inform='Audio;%Channel(s)/String%' " & q
    set aSampleRate to do shell script mediainfoBin & " --Inform='Audio;%SamplingRate/String%' " & q

    set fContainer  to do shell script mediainfoBin & " --Inform='General;%Format%' " & q
    set fSize       to do shell script mediainfoBin & " --Inform='General;%FileSize/String%' " & q
    set fDuration   to do shell script mediainfoBin & " --Inform='General;%Duration/String3%' " & q
    set fName       to do shell script "basename " & q

    set msg to ""

    if vFormat is not "" then
        if vProfile is not "" then
            set msg to msg & "🎬  " & vFormat & " (" & vProfile & ")" & return
        else
            set msg to msg & "🎬  " & vFormat & return
        end if
        if vWidth is not "" then
            set msg to msg & "     " & vWidth & " × " & vHeight & "  •  " & vFps & " fps" & return
        end if
        if vBitrate is not "" then
            set msg to msg & "     " & vBitrate & return
        end if
    end if

    if aFormat is not "" then
        if msg is not "" then set msg to msg & return
        set msg to msg & "🔊  " & aFormat
        if aChannels is not "" then set msg to msg & "  •  " & aChannels
        if aSampleRate is not "" then set msg to msg & "  •  " & aSampleRate
        set msg to msg & return
    end if

    if msg is not "" then set msg to msg & return
    set msg to msg & "📁  " & fContainer & "  •  " & fSize
    if fDuration is not "" then set msg to msg & "  •  " & fDuration

    display dialog msg with title fName buttons {"OK"} default button 1 with icon note
end open
