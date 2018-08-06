{-# OPTIONS_GHC -fno-warn-unticked-promoted-constructors #-}
{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE GADTs         #-}
{-# LANGUAGE LambdaCase    #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE ViewPatterns  #-}
-- | Transform a 'Composition' by deleting children.

module FastCut.Composition.Delete where

import           FastCut.Prelude

import           Control.Lens

import           FastCut.Composition
import           FastCut.Focus
import           FastCut.Focus.Parent

deleteAt :: Int -> [a] -> [a]
deleteAt i xs =
  let (before, after) = splitAt i xs
  in before <> drop 1 after

-- | Delete a 'Composition' or 'CompositionPart' at the 'Focus',
-- returning a new 'Composition' if the focus is valid, and possibly a
-- 'FocuCommand' required to obtain a new valid focus into the new
-- 'Composition'.
delete ::
    Focus ft
  -> Composition a TimelineType
  -> Maybe (Composition a TimelineType, Maybe FocusCommand)
delete focus comp = runStateT (withParentOf traversal focus comp) Nothing
  where
    traversal =
      ParentTraversal
      { onTimeline =
          \i (Timeline ann children') ->
            moveIfAtEnd children' i *>
            pure (Timeline ann (deleteAt i children'))
      , onSequence =
          \i (Sequence ann children') ->
            moveIfAtEnd children' i *>
            pure (Sequence ann (deleteAt i children'))
      , onVideoParts = \i vs -> moveIfAtEnd vs i *> pure (deleteAt i vs)
      , onAudioParts = \i as -> moveIfAtEnd as i *> pure (deleteAt i as)
      }
    moveIfAtEnd :: [a] -> Int -> StateT (Maybe FocusCommand) Maybe ()
    moveIfAtEnd [_] _ = put (Just FocusUp)
    moveIfAtEnd (pred . length -> maxIndex) idx
      | idx >= maxIndex = put (Just FocusLeft)
      | otherwise = pure ()

-- | Same as 'delete', but trying to apply the returned focus command.
delete_ ::
    Focus ft
  -> Composition a TimelineType
  -> Either (FocusCommand, FocusError) (Composition a TimelineType, Focus ft)
delete_ f s =
  case delete f s of
    Nothing -> pure (s, f)
    Just (s', Nothing) -> pure (s', f)
    Just (s', Just cmd) ->
      modifyFocus s cmd f
      & _Left %~ (cmd,)
      <&> (s',)
