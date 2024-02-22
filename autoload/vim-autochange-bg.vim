" vim: ft=vim ts=2 sts=2 sw=2 expandtab fenc=utf-8 ff=unix

"----- [TESTING] Change background automatically

if exists('g:AutoChangeBgLoaded') || &cp
  finish
endif
let g:AutoChangeBgLoaded = 1

let s:save_cpo = &cpo
set cpo&vim

" Function to check internet accesibility
function! CheckInternetConnection()
  let l:target = 'https://www.google.com'

  if executable('curl')
    " Trying to access to Google
    let output = system('curl -s -I ' . l:target . ' | head -n 1')
    echo output
    if match(output, 'HTTP\/[12]\s\+2\d\d') >= 0
      " Success if the code was 2xx
      return v:true
    else
      return v:false
    endif
  elseif executable('wget')
    let output = system('wget --spider -q -S ' . l:target . ' 2>&1')
    if v:shell_error == 0
      return v:true
    else
      return v:false
    endif
  else
    return v:false
  endif
endfunction

" Function to check if the current time is within the specified time range
function! IsTimeInRange(start_time, end_time)
    let l:current_time = strftime('%H%M%S')

    if a:start_time <= current_time && current_time <= a:end_time
        return v:true
    else
        return v:false
    endif
endfunction

" Function to convert from string 'H:M:S P' to 'HHMMSS'
function! ConvertTime12To24(time12)
    let l:pattern = '\v^(\d+):(\d+):(\d+)\s*(AM|PM)$'
    let l:parts = matchlist(a:time12, l:pattern)
    if len(l:parts) == 0
        return 'Invalid time format'
    endif
    let l:hour = str2nr(l:parts[1])
    let l:minute = l:parts[2]
    let l:second = l:parts[3]
    let l:ampm = l:parts[4]

    " Convert 12h system to 24h system
    if l:ampm ==# 'PM' && l:hour != 12
        let l:hour += 12
    elseif l:ampm ==# 'AM' && l:hour == 12
        let l:hour = 0
    endif

    " Filling zero
    let l:hour   = printf('%02d', l:hour)
    let l:minute = printf('%02d', l:minute)
    let l:second = printf('%02d', l:second)

    " return converted strings
    " return l:hour . ':' . l:minute . ':' . l:second
    return l:hour . l:minute . l:second
endfunction

function! GetTimeZone()
  if executable('timedatectl')
    let l:timezone = trim(system("timedatectl | grep 'Time zone' | sed -re 's/^ \+//g' | cut -d ' ' -f 3"))
  elseif executable('curl')
    let l:timezone = trim(system("curl -s 'https://ipinfo.io/json' | jq -r '.timezone'"))
  endif
  return l:timezone
endfunction

function! GetLatLngByIp()
  let l:latlng = split(trim(system("curl -s 'https://ipinfo.io/json' | jq -r '.loc'")), ',')
  return l:latlng
endfunction

" Function to get sunrise and sunset time from internet
function! GetSunriseSunsetTimes()
    let l:timezone = GetTimeZone()
    let l:latlng = GetLatLngByIp()
    " echo 'timezone=' . l:timezone
    " echo 'latlng=' . l:latlng
    let l:sunrise_api = 'curl -s ' . shellescape('https://api.sunrise-sunset.org/json?' . 'lat=' . l:latlng[0] . '&lng=' . l:latlng[1] . '&date=today&tzid=' . l:timezone)
    " echo 'sunrise_api='.l:sunrise_api
    let l:api_result= trim(system(l:sunrise_api . " | jq -r '\"\\(.results.sunrise),\\(.results.sunset)\"'"))
    let l:sunrise_sunset = split(l:api_result, ',')
    " echo 'sunrise='.l:sunrise_sunset[0]
    " echo 'sunset ='.l:sunrise_sunset[1]
    return l:sunrise_sunset
endfunction

" Function to set Vim background color based on OS and desktop environment
function! SetVimBackground()
  if has('unix')
    " For macOS
    if has('macunix')
      let l:theme = system("defaults read -g AppleInterfaceStyle 2>/dev/null")
      if l:theme =~? 'dark'
        set background=dark
      else
        set background=light
      endif

    " For Gnome (Linux)
    elseif system('echo $XDG_CURRENT_DESKTOP') =~? 'gnome'
      let l:theme = system("gsettings get org.gnome.desktop.interface gtk-theme")
      if l:theme =~? 'dark'
        set background=dark
      else
        set background=light
      endif

    " For KDE (Linux)
    elseif system('echo $XDG_CURRENT_DESKTOP') =~? 'kde'
      let l:theme = system("kreadconfig5 --file kdeglobals --group General --key ColorScheme")
      if l:theme =~? 'dark'
        set background=dark
      else
        set background=light
      endif

    " Other unix
    else
      if !exists('s:daylight')
        let s:daylight = GetSunriseSunsetTimes()
        " echo "sunrise=".s:daylight[0]
        " echo "sunset=".s:daylight[1]
        let s:daylight[0] = ConvertTime12To24(s:daylight[0])
        let s:daylight[1] = ConvertTime12To24(s:daylight[1])
        " echo "sunrise=".s:daylight[0]
        " echo "sunset=".s:daylight[1]
      endif
      if IsTimeInRange(s:daylight[0], s:daylight[1])
        set background=light
      else
        set background=dark
      endif

    endif

  " For Windows (not tested yet...)
  elseif has('win32') || has('win64')
    let l:theme = system('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme')
    if l:theme =~ '0x0'
      set background=dark
    else
      set background=light
    endif
endif
endfunction

" Set background color when Vim starts
call SetVimBackground()

" Periodic background color updates
function! UpdateBackground(timer)
  call SetVimBackground()
endfunction

" Set timer to update background every 5 minutes (300000 milliseconds)
let s:background_timer = timer_start(60000, 'UpdateBackground', {'repeat': -1})

let &cpo = s:save_cpo

