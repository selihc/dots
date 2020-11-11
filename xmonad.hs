import qualified Codec.Binary.UTF8.String as UTF8
import qualified Data.Map as M
import Graphics.X11.ExtraTypes.XF86
  ( xF86XK_AudioLowerVolume,
    xF86XK_AudioMute,
    xF86XK_AudioRaiseVolume,
    xF86XK_MonBrightnessDown,
    xF86XK_MonBrightnessUp,
  )
import System.Exit (ExitCode (ExitSuccess), exitWith)
import System.IO
import XMonad
import XMonad.Actions.GroupNavigation
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops (ewmh, fullscreenEventHook)
import XMonad.Hooks.ManageDocks
  ( Direction2D (U),
    ToggleStruts (ToggleStrut),
    avoidStruts,
    docks,
    manageDocks,
  )
import XMonad.Hooks.ManageHelpers
  ( composeOne,
    doFullFloat,
    doRectFloat,
    isFullscreen,
    isKDETrayWindow,
    transience,
    (-?>),
  )
import XMonad.Hooks.SetWMName ()
import XMonad.Layout
import XMonad.Layout.DwmStyle
import XMonad.Layout.IfMax
import XMonad.Layout.LayoutModifier
import XMonad.Layout.Minimize
import XMonad.Layout.NoBorders
import XMonad.Layout.Spacing
import XMonad.Prompt
import XMonad.Prompt.FuzzyMatch
import XMonad.Prompt.Shell
import qualified XMonad.StackSet as W
import XMonad.Util.EZConfig (additionalKeys)
import XMonad.Util.NamedScratchpad
import XMonad.Util.Run (spawnPipe)
import XMonad.Util.Themes

main :: IO ()
main = do
  xmonad $ ewmh $ docks myConfig

myScreenshot = "maim -s | tee ~/screenshots/$(date +%s).png | xclip -selection clipboard -t image/png && notify-send 'Screenshot Taken'"

myScratchPads :: [NamedScratchpad]
myScratchPads =
  [ NS "terminal" spawnTerm findTerm manageTerm
  ]
  where
    spawnTerm = "kitty --class scratchpad"
    findTerm = resource =? "scratchpad"
    manageTerm = doRectFloat $ W.RationalRect l t w h
      where
        h = 0.4
        w = 0.6
        t = 0.05
        l = 0.2

myXPromptConfig :: XPConfig
myXPromptConfig =
  XPC
    { promptBorderWidth = 4,
      alwaysHighlight = True,
      height = 64,
      historySize = 256,
      font = "xft:Iosevka:regular:pixelsize=24",
      bgColor = "#171e37",
      fgColor = "#f5f5f5",
      bgHLight = "#9d2f2f",
      fgHLight = "#f5f5f5",
      borderColor = "#9d2f2f",
      position = CenteredAt 0.3 0.5,
      autoComplete = Just 50,
      showCompletionOnTab = True,
      searchPredicate = fuzzyMatch,
      defaultPrompter = id,
      sorter = const id,
      maxComplRows = Just 10,
      promptKeymap = defaultXPKeymap,
      completionKey = (0, xK_Tab),
      changeModeKey = xK_grave,
      historyFilter = id,
      defaultText = []
    }

myKeys conf@(XConfig {XMonad.modMask = modMask}) =
  M.fromList $
    ----------------------------------------------------------------------
    -- Custom key bindings
    --

    -- Start a terminal.  Terminal to start is specified by myTerminal variable.
    [ ( (modMask .|. shiftMask, xK_Return),
        spawn $ XMonad.terminal conf
      ),
      -- Take a selective screenshot using the command specified by mySelectScreenshot.
      ( (0, xK_Print),
        spawn myScreenshot
      ),
      ((modMask, xK_p), shellPrompt myXPromptConfig),
      -- Mute volume.
      ( (0, xF86XK_AudioMute),
        spawn "pactl set-sink-mute 0 toggle && notify-send 'mute toggled'"
      ),
      -- Decrease volume.
      ( (0, xF86XK_AudioLowerVolume),
        spawn "pactl set-sink-volume 0 -5% && notify-send \"volume $(pamixer --get-volume)\""
      ),
      -- Increase volume.
      ( (0, xF86XK_AudioRaiseVolume),
        spawn "pactl set-sink-volume 0 +5% && notify-send volume $(pamixer --get-volume)"
      ),
      -- raise brightness
      ( (0, xF86XK_MonBrightnessUp),
        spawn "xbacklight +10% && notify-send brightness $(xbacklight)"
      ),
      -- lower brightness
      ( (0, xF86XK_MonBrightnessDown),
        spawn "xbacklight -10% && notify-send brightness $(xbacklight)"
      ),
      -- Scratchpads
      ((modMask, xK_grave), namedScratchpadAction myScratchPads "terminal"),
      --------------------------------------------------------------------
      -- "Standard" xmonad key bindings
      --

      -- Close focused window.
      ( (modMask .|. shiftMask, xK_c),
        kill
      ),
      -- Cycle through the available layout algorithms.
      ( (modMask, xK_space),
        sendMessage NextLayout
      ),
      --  Reset the layouts on the current workspace to default.
      ( (modMask .|. shiftMask, xK_space),
        setLayout $ XMonad.layoutHook conf
      ),
      -- Resize viewed windows to the correct size.
      ( (modMask, xK_n),
        refresh
      ),
      -- Move focus to the next window.
      ( (modMask, xK_Tab),
        windows W.focusDown
      ),
      -- Move focus to the next window.
      ( (modMask, xK_j),
        windows W.focusDown
      ),
      -- Move focus to the previous window.
      ( (modMask, xK_k),
        windows W.focusUp
      ),
      -- Move focus to the master window.
      ( (modMask, xK_m),
        windows W.focusMaster
      ),
      -- Swap the focused window and the master window.
      ( (modMask, xK_Return),
        windows W.swapMaster
      ),
      -- Swap the focused window with the next window.
      ( (modMask .|. shiftMask, xK_j),
        windows W.swapDown
      ),
      -- Swap the focused window with the previous window.
      ( (modMask .|. shiftMask, xK_k),
        windows W.swapUp
      ),
      -- Shrink the master area.
      ( (modMask, xK_h),
        sendMessage Shrink
      ),
      -- Expand the master area.
      ( (modMask, xK_l),
        sendMessage Expand
      ),
      -- Push window back into tiling.
      ( (modMask, xK_t),
        withFocused $ windows . W.sink
      ),
      -- Quit xmonad.
      ( (modMask .|. shiftMask, xK_q),
        io (exitWith ExitSuccess)
      ),
      ((modMask .|. controlMask, xK_0), sendMessage $ ToggleStrut U),
      -- Restart xmonad.
      ( (modMask, xK_q),
        restart "xmonad" True
      )
    ]
      ++
      -- mod-[1..9], Switch to workspace N
      -- mod-shift-[1..9], Move client to workspace N
      [ ((m .|. modMask, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9],
          (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]
      ]
      ++
      -- mod-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
      -- mod-shift-{w,e,r}, Move client to screen 1, 2, or 3
      [ ((m .|. modMask, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_w, xK_e, xK_r] [0 ..],
          (f, m) <- [(W.view, 0), (W.shift, shiftMask)]
      ]

-- Main configuration, override the defaults to your liking.
myConfig =
  def
    { terminal = "kitty -1 --instance-group=xmonad",
      logHook = dynamicLogWithPP sjanssenPP >> historyHook,
      layoutHook = myLayoutHook,
      normalBorderColor = "#4c4c4c",
      focusedBorderColor = "#9d2f2f",
      borderWidth = 2,
      handleEventHook = fullscreenEventHook,
      keys = myKeys,
      clickJustFocuses = False,
      workspaces = myWorkspaces,
      manageHook =
        composeOne
          [ isKDETrayWindow -?> doIgnore,
            transience,
            isFullscreen -?> doFullFloat
          ]
          <+> namedScratchpadManageHook myScratchPads
          <+> manageDocks
    }

myWorkspaces = ["1", "2", "3", "4", "5"]

decoTheme :: Theme
decoTheme =
  def
    { fontName = "xft:Iosevka:regular:pixelsize=12",
      activeColor = "#171e37",
      urgentColor = "#ca8049",
      inactiveColor = "#171e37",
      inactiveTextColor = "#c5c8c6",
      inactiveBorderWidth = 4,
      inactiveBorderColor = "#171e37",
      activeTextColor = "#c5c8c6",
      decoHeight = 24
    }

myLayoutHook = avoidStruts $ ifMax 1 (noBorders $ Full) (smartBorders $ dwmStyle shrinkText decoTheme $ spacingRaw True (Border 4 4 4 4) True (Border 4 4 4 4) True $ tiled)
  where
    -- default tiling algorithm partitions the screen into two panes
    tiled = Tall nmaster delta ratio

    -- The default number of windows in the master pane
    nmaster = 1

    -- Default proportion of screen occupied by master pane
    ratio = 1 / 2

    -- Percent of screen to increment by when resizing panes
    delta = 3 / 100
