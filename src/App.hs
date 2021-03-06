module App
  ( runMatterhorn
  )
where

import           Prelude ()
import           Prelude.Compat

import           Brick
import qualified Graphics.Vty as Vty
import           Lens.Micro.Platform
import           System.IO (IOMode(WriteMode), openFile, hClose)
import           Text.Aspell (stopAspell)

import           Config
import           Options
import           State.Setup
import           Events
import           Draw
import           Types

app :: App ChatState MHEvent Name
app = App
  { appDraw         = draw
  , appChooseCursor = showFirstCursor
  , appHandleEvent  = onEvent
  , appStartEvent   = return
  , appAttrMap      = (^.csResources.crTheme)
  }

runMatterhorn :: Options -> Config -> IO ChatState
runMatterhorn opts config = do
    logFile <- case optLogLocation opts of
      Just path -> Just `fmap` openFile path WriteMode
      Nothing   -> return Nothing

    st <- setupState logFile config

    let mkVty = do
          vty <- Vty.mkVty Vty.defaultConfig
          let output = Vty.outputIface vty
          Vty.setMode output Vty.BracketedPaste True
          Vty.setMode output Vty.Hyperlink True
          return vty

    finalSt <- customMain mkVty (Just $ st^.csResources.crEventQueue) app st

    case finalSt^.csEditState.cedSpellChecker of
        Nothing -> return ()
        Just (s, _) -> stopAspell s

    case logFile of
      Nothing -> return ()
      Just h -> hClose h

    return finalSt
