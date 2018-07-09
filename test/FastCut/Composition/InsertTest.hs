{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -fno-warn-missing-signatures #-}

module FastCut.Composition.InsertTest where

import           FastCut.Prelude
import qualified Prelude

import           Test.Tasty.Hspec

import           FastCut.Composition
import           FastCut.Composition.Insert
import           FastCut.Focus


video4s = Clip $ VideoClip () (ClipMetadata "video-1" "/tmp/1.mp4" 4)
video10s = Clip $ VideoClip () (ClipMetadata "video-2" "/tmp/2.mp4" 10)
audio1s = Clip $ AudioClip () (ClipMetadata "audio-1" "/tmp/1.m4a" 1)
audio4s = Clip $ AudioClip () (ClipMetadata "audio-2" "/tmp/2.m4a" 4)
audio10s = Clip $ AudioClip () (ClipMetadata "audio-3" "/tmp/3.m4a" 10)
gap1s = Gap () 1
gap3s = Gap () 3
parallel1 = Parallel () [gap1s, video4s] [audio1s]
parallel2 = Parallel () [gap3s, video10s] [audio4s, audio10s]

seqWithTwoParallels = Sequence () [parallel1, parallel2]

timelineTwoParallels = Timeline () [Sequence () [], seqWithTwoParallels]

spec_insertRightOf = do
  it "appends a sequence after the focused one" $ do
    let focus = SequenceFocus 0 Nothing
        before' = Timeline (1 :: Int) [Sequence 2 [], Sequence 4 []]
        after' = Timeline 1 [Sequence 2 [], Sequence 3 [], Sequence 4 []]
    insert focus (InsertSequence (Sequence 3 [])) RightOf before' `shouldBe`
      Just after'
  it "appends a video clip after the focused one" $ do
    let focus =
          SequenceFocus 0 (Just (ParallelFocus 0 (Just (ClipFocus Video 0))))
        before' = Timeline () [Sequence () [Parallel () [video4s, video10s] []]]
        after' =
          Timeline () [Sequence () [Parallel () [video4s, gap3s, video10s] []]]
    insert focus (InsertVideoPart gap3s) RightOf before' `shouldBe` Just after'

{-# ANN module ("HLint: ignore Use camelCase" :: Prelude.String) #-}