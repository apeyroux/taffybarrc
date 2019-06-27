-- -*- mode:haskell -*-
module Main where

import System.Taffybar
import System.Taffybar.Hooks
import System.Taffybar.Information.CPU
import System.Taffybar.Information.Memory
import System.Taffybar.SimpleConfig
import System.Taffybar.Widget.SimpleClock
import System.Taffybar.Widget
import System.Taffybar.Widget.Generic.PollingGraph
import System.Taffybar.Widget.Generic.PollingLabel
import System.Taffybar.Widget.Util
import System.Taffybar.Widget.Workspaces
import System.Taffybar.Widget.FreedesktopNotifications
import System.Taffybar.Widget.Battery

transparent = (0.0, 0.0, 0.0, 0.0)
yellow1 = (0.9453125, 0.63671875, 0.2109375, 1.0)
yellow2 = (0.9921875, 0.796875, 0.32421875, 1.0)
green1 = (0, 1, 0, 1)
green2 = (1, 0, 1, 0.5)
taffyBlue = (0.129, 0.588, 0.953, 1)

myGraphConfig =
  defaultGraphConfig
  { graphPadding = 0 -- -1
  , graphBorderWidth = 1 -- 0
  , graphWidth = 68 -- 75
  , graphBackgroundColor = transparent
  }

netCfg = myGraphConfig
  { graphDataColors = [yellow1, yellow2]
 -- , graphLabel = Just "net"
  }

memCfg = myGraphConfig
  { graphDataColors = [taffyBlue]
 --, graphLabel = Just "mem"
  }

cpuCfg = myGraphConfig
  { graphDataColors = [green1, green2]
--   , graphLabel = Just "cpu"
  }

memCallback :: IO [Double]
memCallback = do
  mi <- parseMeminfo
  return [memoryUsedRatio mi]

cpuCallback = do
  (_, systemLoad, totalLoad) <- cpuLoad
  return [totalLoad, systemLoad]

main = do
  let myWorkspacesConfig = defaultWorkspacesConfig { 

        showWorkspaceFn = hideEmpty
      }
      workspaces = workspacesNew myWorkspacesConfig
      cpu = pollingGraphNew cpuCfg 0.5 cpuCallback
      tray = sniTrayNew
      clock = textClockNew Nothing "%d/%m/%Y %H:%M" 5
      mem = pollingGraphNew memCfg 1 memCallback
      net = networkGraphNew netCfg (Just ["wlp2s0"])
      layout = layoutNew defaultLayoutConfig
      windows = windowsNew defaultWindowsConfig
      -- tray = sniTrayNew
      -- tray = sniTrayThatStartsWatcherEvenThoughThisIsABadWayToDoIt
      myConfig = defaultSimpleTaffyConfig
        { startWidgets =
            workspaces : map (>>= buildContentsBox) [ layout, windows ]
        , endWidgets = map (>>= buildContentsBox)
          [
          -- tray
           clock
          , net
          , mem
          , cpu
          -- , notifyAreaNew defaultNotificationConfig
          ]
        , barPosition = Bottom
        , barPadding = 1
        , barHeight = 30
        , widgetSpacing = 1
        }
  dyreTaffybar $ withBatteryRefresh $ withLogServer $ withToggleServer $ toTaffyConfig myConfig
