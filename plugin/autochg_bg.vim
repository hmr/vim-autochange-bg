" vim: ft=vim ts=2 sts=2 sw=2 expandtab fenc=utf-8 ff=unix

" vim-autochange-bg
"
" A Vim plugin that automatically changes background color according to system settings or
" local time retrieved from the Internet based on IP address.
"
" Copyright (c) 2024 hmr
"

if exists('g:loaded_autochg_bg') || &cp
  finish
endif
let g:loaded_autochg_bg= 1

let s:save_cpo = &cpo
set cpo&vim

" -----------------------------------------------------------------------------
" ----- Commands
" -----------------------------------------------------------------------------
function! s:AutochgBgToggle()
  call autochg_bg#toggle()
endfunction

function! s:AutochgBgEnable()
  call autochg_bg#enable()
endfunction

function! s:AutochgBgDisable()
  call autochg_bg#disable()
endfunction

" Commands
command! -bar AutochgBgToggle  call s:AutochgBgToggle()
command! -bar AutochgBgEnable  call s:AutochgBgEnable()
command! -bar AutochgBgDisable call s:AutochgBgDisable()

" -----------------------------------------------------------------------------
" ----- Options
" -----------------------------------------------------------------------------
" Initializes a given variable to a given value. The variable is only
" initialized if it does not exist prior.
function s:InitVariable(var, value)
  if !exists(a:var)
    if type(a:value) == type('')
      exec 'let ' . a:var . ' = ' . "'" . a:value . "'"
    else
      exec 'let ' . a:var . ' = ' .  a:value
    endif
  endif
endfunction

" Interval to check if the system should be set to dark or light mode.
" Default 60000ms (=60sec)
call s:InitVariable('g:autochg_bg_check_interval', 60000)
" Interval to update sunrise and sunset time.
" Default 86400 sec (=24 hours)
call s:InitVariable('g:autochg_bg_geoip_check_interval', 86400)
" Enable this plugin on Vim startup
" Default 0 (=Disabled)
call s:InitVariable('g:autochg_bg_enable_on_vim_startup', 0)

" Force to use GeoIP service
call s:InitVariable('g:autochg_bg_force_geoip', 0)

call s:InitVariable('g:autochg_bg_force_macos', 0)
call s:InitVariable('g:autochg_bg_force_gnome', 0)
call s:InitVariable('g:autochg_bg_force_kde', 0)
call s:InitVariable('g:autochg_bg_force_windows', 0)

" Manually set latitude and longitude
call s:InitVariable('g:autochg_bg_latitude', -1)
call s:InitVariable('g:autochg_bg_longitude', -1)

" No need to touch
call s:InitVariable('g:autochg_bg_timer_id', 0)
call s:InitVariable('g:autochg_bg_geoip_check_time', 0)

" -----------------------------------------------------------------------------
" ----- Auto command
" -----------------------------------------------------------------------------
augroup autochg_bg
  autocmd!
  if g:autochg_bg_enable_on_vim_startup
    autocmd VimEnter * :AutochgBgEnable
  endif
augroup END

let &cpo = s:save_cpo

