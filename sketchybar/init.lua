require("install.sbar")

sbar = require("sketchybar")

sbar.begin_config()
sbar.hotload(true)

require("constants")
require("config")
require("bar")
require("default")

package.loaded["items"] = nil
package.loaded["items.spaces"] = nil
require("items")

sbar.end_config()
sbar.event_loop()
