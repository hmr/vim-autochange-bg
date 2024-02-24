# vim-autochange-bg

This vim plugin changes the background color to light or dark according to the system's theme setting. If the system's theme setting cannot be obtained, this plugin sets the background color by determining the daylight time from the latitude and longitude based on the IP address. (so-called GeoIP).

## Install

### VimPlug

```vim
Plug 'hmr/vim-autochange-bg'
```

## Usage

```vim
:AutochgBgEnable    " Start plugin
:AutochgBgDisable   " Stop plugin
:AutochgBgToggle    " Toggle plugin behavier
```

## Configuration

To enable plugin automatically at vim startup, Add the code below to vimrc.

```vim
let g:autochg_bg_enable_on_vim_startup = 1
```

Other settings are following:

`g:autochg_bg_check_interval`
: Interval time to determine dark or light in msec. Default: 60000 (a minute)

`g:autochg_bg_geoip_check_interval`
: Interval time to obtain daylight time from internet service in sec. Default 86400 (a day)

`g:autochg_bg_force_macos`
: Force macOS way to get system theme settings.

`g:autochg_bg_force_gnome`
: Force GNOME way to get system theme settings.

`g:autochg_bg_force_kde`
: Force KDE way to get system theme settings.

`g:autochg_bg_force_windows`
: Force Windows way to get system theme settings.

`g:autochg_bg_force_geoip`
: Force to use internet GeoIP service to get system theme settings.
