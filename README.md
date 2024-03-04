# vim-autochange-bg

According to the system's theme setting, this plugin changes the Vim's background to light or dark. If the system's theme setting cannot be obtained, this plugin sets the background by determining the daylight time from the latitude and longitude based on the IP address. (so-called GeoIP).

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

To enable plugin automatically at vim startup, add the code below to vimrc.

```vim
let g:autochg_bg_enable_on_vim_startup = 1
```

All settings are following:

| Variable | Default | Description |
|----------|---------|-------------|
| `g:autochg_bg_enable_on_vim_startup` | 0   | Enable this plugin on Vim startup. |
| `g:autochg_bg_check_interval`      | 60000 | Interval time to determine dark or light in msec. |
| `g:autochg_bg_geoip_check_interval`| 86400 | Interval time to obtain daylight time from internet service in sec. |
| `g:autochg_bg_force_macos`         | 0     | Force macOS way to get system theme settings. |
| `g:autochg_bg_force_gnome`         | 0     | Force GNOME way to get system theme settings. |
| `g:autochg_bg_force_kde`           | 0     | Force KDE way to get system theme settings. |
| `g:autochg_bg_force_windows`       | 0     | Force Windows way to get system theme settings. |
| `g:autochg_bg_force_geoip`         | 0     | Force to use internet GeoIP service to get system theme settings. |
| `g:autochg_bg_latitude`            | -1    | Manually set latitude. |
| `g:autochg_bg_longitude`           | -1    | Manually set longitude. |

## Notes

1. This plugin will use following web services

   | Objective | URL |
   |-----------|-----|
   | To obtain timezone               | http://ipinfo.io           |
   | To obtain latitude and longitude | http://ipinfo.io           |
   | To obtain daylight time          | https://sunrise-sunset.org |

