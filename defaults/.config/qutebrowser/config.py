# Autogenerated config.py
# Documentation:
#   qute://help/configuring.html
#   qute://help/settings.html

#  Wed Jan 09 2019 01:31
#  Dropping support after so much work:
#  Uses the chromium web engine
#  Ergo not even that light weight
#  Must protect firefox

import platform
import socket

from qutebrowser.config.config import ConfigContainer  # noqa: F401
# pylint: disable=C0111
from qutebrowser.config.configfiles import ConfigAPI  # noqa: F401

config = config  # type: ConfigAPI # noqa: F821 pylint: disable=E0602,C0103
c = c  # type: ConfigContainer # noqa: F821 pylint: disable=E0602,C0103


# Uncomment this to still load settings configured via autoconfig.yml
# config.load_autoconfig()

# Enable JavaScript.
# Type: Bool
#  config.set('content.javascript.enabled', True, 'file://*')

# Enable JavaScript.
# Type: Bool
#  config.set('content.javascript.enabled', True, 'chrome://*/*')

# Enable JavaScript.
# Type: Bool
#  config.set('content.javascript.enabled', True, 'qute://*/*')

# Bindings for normal mode
config.bind('d', 'scroll-page 0 0.5')
config.bind('e', 'scroll-page 0 -0.5')
config.bind('q', 'tab-close')
config.bind('<Shift-t', 'open -t', mode='normal')
config.bind('<Alt-[>', 'tab-next', mode='normal')
config.bind('<Alt-]>', 'tab-prev', mode='normal')
config.bind('<Shift-k>', 'tab-next', mode='normal')
config.bind('<Shift-j>', 'tab-prev', mode='normal')
config.bind('<Ctrl-l>', 'messages', mode='normal')

#  pip install --user tldextract
config.bind('<z><l>', 'spawn --userscript qute-pass')
config.bind('<z><u><l>', 'spawn --userscript qute-pass --username-only')
config.bind('<z><p><l>', 'spawn --userscript qute-pass --password-only')

#  Will be discontinued
#  c.backend = "webkit"

c.content.pdfjs = True

c.spellcheck.languages = ["en-US"]

#  Editor shows under journal scratchpad
#  Cant use nvr need nvim use it with <c-e>
c.editor.command = [
    "nvr", "--remote-tab-silent", "+set bufhidden=delete",
    "+normal {line}G{column0}l", "--servername", "/tmp/nada", "{file}"
]

hostname = socket.gethostname()
if (platform.system() != 'Windows'
        and (hostname == 'predator' or hostname == 'surbook')):
    #  hidpi
    #  c.qt.highdpi = True
    #  c.zoom.default ="125%"
    c.fonts.completion.category = "8pt monospace"
    c.fonts.completion.entry = "8pt monospace"
    c.fonts.debug_console = "8pt monospace"
    c.fonts.downloads = "8pt monospace"
    c.fonts.hints = "8pt monospace"
    c.fonts.keyhint = "8pt monospace"
    c.fonts.messages.error = "8pt monospace"
    c.fonts.messages.info = "8pt monospace"
    c.fonts.messages.warning = "8pt monospace"
    c.fonts.statusbar = "8pt monospace"
    c.fonts.tabs = "8pt monospace"

c.downloads.location.directory = '/home/reinaldo/Downloads'

c.url.searchengines['a'] = 'https://wiki.archlinux.org/?search={}'
c.url.searchengines['y'] = 'https://www.youtube.com/results?search_query={}'
c.url.searchengines[
    'w'] = 'https://secure.wikimedia.org/wikipedia/en/w/index.php?title=Special%%3ASearch&search={}'
c.url.searchengines['g'] = 'https://github.com/search?q={}&type=Code'

#  Privacy settings
#  Not available while using webengine backend
#  c.content.notifications = False
#  c.content.geolocation = False
#  c.content.canvas_reading = False
#  c.content.headers.custom = {
    #  "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
#  }
#  c.content.webgl = False
#  c.content.javascript.enabled = False
#  c.content.cookies.accept = "never"
#  c.content.cookies.store = False

#  https://developer.chrome.com/apps/match_patterns
#  config.set('content.javascript.enabled', True, 'https://*.twitch.tv/*')
#  config.set('content.cookies.accept', "all", '*/twitch.tv*')
