# awesome-opacity

This module provides automatic and manual control of opacity for
active/inactive clients in [awesome](https://awesome.naquadah.org).

## Installation

Add this to your rc.lua:

    local opacity = require("lib/awesome-opacity")

See the `init.lua` file for possible keybindings.

You might also want to adjust it to your needs, e.g. Firefox is handled in
a special way currently.

The plan is to allow to configure it using `awful.rules` in the future.
