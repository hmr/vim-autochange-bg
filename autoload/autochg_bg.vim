" vim: ft=vim ts=2 sts=2 sw=2 expandtab fenc=utf-8 ff=unix fdm=indent

" vim-autochange-bg
" A Vim plugin that automatically changes background color according to system settings or
" local time retrieved from the Internet based on IP address.

" Copyright (c) 2024 hmr

" Function to check internet accesibility
function! s:CheckInternetConnection()
  let l:target = 'https://www.google.com'

  if executable('curl')
    " Trying to access to Google
    let output = system('curl -Ls -I ' . l:target . ' | head -n 1')
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
function! s:IsTimeInRange(start_time, end_time)
    let l:current_time = strftime('%H%M%S')

    if a:start_time <= current_time && current_time <= a:end_time
        return v:true
    else
        return v:false
    endif
endfunction

" Function to convert from string 'H:M:S P' to 'HHMMSS'
function! s:ConvertTime12To24(time12)
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

function! s:HttpGetCommand(url)
  if executable('curl')
    return 'curl -Ls ' . shellescape(a:url)
  elseif executable('wget')
    return 'wget -qO- ' . shellescape(a:url)
  endif
  return ''
endfunction

function! s:DoSetBackground(background)
  if &background !=# a:background
    execute 'set background=' . a:background
  endif
endfunction

function! s:GetTimeZone()
  let l:zoneinfo_file = expand('/etc/localtime')
  let l:timezone = ''
  if executable('timedatectl')
    " echom 'Getting timezone by timedatectl'
    let l:timezone = trim(system("timedatectl | grep 'Time zone' | sed -re 's/^ \+//g' | cut -d ' ' -f 3"))
  elseif filereadable(l:zoneinfo_file) && getftype(l:zoneinfo_file) ==# 'link'
    " echom 'Getting timezone by ' . l:zoneinfo_file
    let l:timezone = join(split(system('readlink /etc/localtime'), '/')[-2:], "/")
  elseif executable('jq')
    " echom 'Getting timezone by ipinfo.io'
    let l:fetch_cmd = s:HttpGetCommand('https://ipinfo.io/json')
    if !empty(l:fetch_cmd)
      let l:timezone = trim(system(l:fetch_cmd . " | jq -r '.timezone'"))
    endif
  endif
  return substitute(l:timezone, '\%x00', '', 'g')
endfunction

function! GetLatLngByIp()
  if !executable('jq')
    return []
  endif

  let l:fetch_cmd = s:HttpGetCommand('https://ipinfo.io/json')
  if empty(l:fetch_cmd)
    return []
  endif

  let l:latlng = split(trim(system(l:fetch_cmd . " | jq -r '.loc'")), ',')
  return l:latlng
endfunction

" Function to get sunrise and sunset time from internet
function! s:GetSunriseSunsetTimes()
    if !executable('jq')
      return []
    endif

    let l:timezone = s:GetTimeZone()
    " echom 'timezone=' . l:timezone
    if g:autochg_bg_latitude ==# -1 && g:autochg_bg_longitude ==# -1
      let l:latlng = GetLatLngByIp()
    else
      let l:latlng = [g:autochg_bg_latitude, g:autochg_bg_longitude ]
    endif
    if len(l:latlng) < 2
      return []
    endif
    " echom 'latlng=' . l:latlng[0] . ',' . l:latlng[1]

    let l:sunrise_api = s:HttpGetCommand('https://api.sunrise-sunset.org/json?' . 'lat=' . l:latlng[0] . '&lng=' . l:latlng[1] . '&date=today&tzid=' . l:timezone)
    if empty(l:sunrise_api)
      return []
    endif
    " echom 'sunrise_api=' . l:sunrise_api
    let l:api_result= trim(system(l:sunrise_api . " | jq -r '\"\\(.results.sunrise),\\(.results.sunset)\"'"))
    let l:sunrise_sunset = split(l:api_result, ',')
    " echom 'sunrise(12h)=' . l:sunrise_sunset[0]
    " echom 'sunset (12h)=' . l:sunrise_sunset[1]
    return l:sunrise_sunset
endfunction

" Function to determine background color light or dark
function! s:DetermineBgColorByIp()
  try
    " Only gets daylight hours once every 24 hours
    if !exists('g:autochg_bg_daylights')
      \ || (strftime('%s') - g:autochg_bg_geoip_check_time >= g:autochg_bg_geoip_check_interval)
      let g:autochg_bg_daylights = s:GetSunriseSunsetTimes()
      let g:autochg_bg_daylights[0] = s:ConvertTime12To24(g:autochg_bg_daylights[0])
      let g:autochg_bg_daylights[1] = s:ConvertTime12To24(g:autochg_bg_daylights[1])
      " echom "sunrise(24h)=".g:autochg_bg_daylights[0]
      " echom "sunset (24h)=".g:autochg_bg_daylights[1]
      let g:autochg_bg_geoip_check_time = strftime('%s')
    endif
    if s:IsTimeInRange(g:autochg_bg_daylights[0], g:autochg_bg_daylights[1])
      call s:DoSetBackground('light')
    else
      call s:DoSetBackground('dark')
    endif
  catch
    " Do nothing
    " echom 'Error: ' . v:exception
  endtry
endfunction

" Periodic background color updates
function! s:UpdateBackground(timer)
  call autochg_bg#SetVimBackground()
endfunction

" Function to set Vim background color based on OS and desktop environment
function! autochg_bg#SetVimBackground()
  if !g:autochg_bg_force_geoip
    \ && (has('unix') || g:autochg_bg_force_macos || g:autochg_bg_force_gnome || g:autochg_bg_force_kde)

    " For macOS
    if has('macunix') || g:autochg_bg_force_macos
      let l:theme = system("defaults read -g AppleInterfaceStyle 2>/dev/null")
      if l:theme =~? 'dark'
        call s:DoSetBackground('dark')
      else
        call s:DoSetBackground('light')
      endif

    " For Gnome
    elseif system('echo $XDG_CURRENT_DESKTOP') =~? 'gnome' || g:autochg_bg_force_gnome
      let l:theme = system("gsettings get org.gnome.desktop.interface gtk-theme")
      if l:theme =~? 'dark'
        call s:DoSetBackground('dark')
      else
        call s:DoSetBackground('light')
      endif

    " For KDE
    elseif system('echo $XDG_CURRENT_DESKTOP') =~? 'kde' || g:autochg_bg_force_kde
      let l:theme = system("kreadconfig5 --file kdeglobals --group General --key ColorScheme")
      if l:theme =~? 'dark'
        call s:DoSetBackground('dark')
      else
        call s:DoSetBackground('light')
      endif

    " Other unix
    else
      call s:DetermineBgColorByIp()
    endif

  " For Windows (not tested yet...)
  elseif !g:autochg_bg_force_geoip && (has('win32') || has('win64') || g:autochg_bg_force_windows)
    let l:theme = system('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme')
    if l:theme =~ '0x0'
      call s:DoSetBackground('dark')
    else
      call s:DoSetBackground('light')
    endif

  " Other system or force GeoIP
  else
    call s:DetermineBgColorByIp()
  endif
endfunction

" Disable plugin
function autochg_bg#disable()
  if g:autochg_bg_timer_id
    call timer_stop(g:autochg_bg_timer_id)
  endif
  let g:autochg_bg_timer_id = 0
endfunction

" Enable plugin
function autochg_bg#enable()
  " Refresh background even when the timer is already running.
  call autochg_bg#SetVimBackground()

  if !g:autochg_bg_timer_id
    " Set timer to update background every 1 minutes (60000 milliseconds)
    let g:autochg_bg_timer_id = timer_start(g:autochg_bg_check_interval, function('s:UpdateBackground'), {'repeat': -1})
  endif
endfunction

" Toggle behavier
function autochg_bg#toggle()
  if g:autochg_bg_timer_id
    call autochg_bg#disable
  else
    call autochg_bg#enable
  endif
endfunction

" Show timer ID
function autochg_bg#show_timer_id()
  if g:autochg_bg_timer_id
    echo g:autochg_bg_timer_id
  else
    echo 'No timer is set.'
  endif
endfunction

" Show timer detail
function autochg_bg#show_timer_info()
  if g:autochg_bg_timer_id
    echo timer_info(g:autochg_bg_timer_id)
  else
    echo 'No timer is set.'
  endif
endfunction

" Show GeoIP acquisition time
function autochg_bg#show_geoip_time()
  if exists('g:autochg_bg_geoip_check_time')
    echo 'GeoIP acquisition time: ' . strftime('%Y-%m-%d %H:%M:%S', g:autochg_bg_geoip_check_time)
  else
    echo 'No GeoIP is acquired.'
  endif
endfunction

" Show sunrise and sunset time
function autochg_bg#show_sunrise_sunset_time()
  if exists('g:autochg_bg_daylights')
    let sunrise_hour = strpart(g:autochg_bg_daylights[0], 0 ,2)
    let sunrise_min  = strpart(g:autochg_bg_daylights[0], 2 ,2)
    let sunrise_sec  = strpart(g:autochg_bg_daylights[0], 4 ,2)
    let sunset_hour  = strpart(g:autochg_bg_daylights[1], 0 ,2)
    let sunset_min   = strpart(g:autochg_bg_daylights[1], 2 ,2)
    let sunset_sec   = strpart(g:autochg_bg_daylights[1], 4 ,2)
    let sunrise      = sunrise_hour . ':' . sunrise_min . ':' . sunrise_sec
    let sunset       = sunset_hour  . ':' . sunset_min  . ':' . sunset_sec
    echo 'Sunrise: ' . sunrise . '/ Sunset: ' . sunset
  else
    echo 'No daylight time is provided.'
  endif
endfunction
