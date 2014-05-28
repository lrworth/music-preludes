
{-# LANGUAGE OverloadedStrings, TypeFamilies #-}

import Music.Prelude.Standard hiding (open, play, openAndPlay)
import qualified Music.Score as Score
import Control.Concurrent.Async
import Control.Applicative
import System.Process (system)

{-    
    Arvo Pärt: Cantus in Memory of Benjamin Britten (1977)

    Inspired by the Abjad transcription
-}

main :: IO ()
main = open music

ensemble :: [Part]
ensemble = [solo tubularBells] <> (divide 2 (tutti violin)) <> [tutti viola] <> [tutti cello] <> [tutti doubleBass]

music :: Score Note
music = meta $ stretch (3/2) $ {-before 60-} (mempty <> bell <> delay 6 strings)
    where
        meta = id
          . title "Cantus in Memoriam Benjamin Britten" 
          . composer "Arvo Pärt" 
          . timeSignature (6/4) 
          . tempo (metronome (1/4) 120)

withTintin :: (HasPitches' a, Score.Pitch a ~ Behavior Pitch) => Pitch -> Score a -> Score a
withTintin p x = x <> tintin p x

-- | Given the melody voice return the tintinnabular voice.
tintin :: (HasPitches' a, Score.Pitch a ~ Behavior Pitch) => Pitch -> Score a -> Score a
tintin tonic = pitches . mapped %~ relative tonic tintin'

-- | 
-- Given the melody interval (relative tonic), returns the tintinnabular voice interval. 
--
-- That is return the highest interval that is a member of the tonic minorTriad in any octave
-- which is also less than the given interval 
--
tintin' :: Interval -> Interval
tintin' melInterval 
    | isNegative melInterval = error "tintin: Negative interval"
    | otherwise = last $ takeWhile (< melInterval) $ tintinNotes
    where
        tintinNotes = concat $ iterate (fmap (+ _P8)) minorTriad
        minorTriad = [_P1,m3,_P5]


bell :: Score Note
bell = let
    cue :: Score (Maybe Note)
    cue = stretchTo 1 (rest |> a) 
    in parts' .~ (ensemble !! 0) $ text "l.v." $ mcatMaybes $ times 40 $ scat [times 3 $ scat [cue,rest], rest^*2]

strings :: Score Note
strings = strings_vln1 <> strings_vln2 <> strings_vla <> strings_vc <> strings_db

strings_vln1 = clef GClef $ parts' .~ (ensemble !! 1) $ up (_P8^*1)   $ strings_cue
strings_vln2 = clef GClef $ parts' .~ (ensemble !! 2) $ up (_P8^*0)   $ stretch 2 strings_cue
strings_vla  = clef CClef $ parts' .~ (ensemble !! 3) $ down (_P8^*1) $ stretch 4 strings_cue
strings_vc   = clef FClef $ parts' .~ (ensemble !! 4) $ down (_P8^*2) $ stretch 8 strings_cue
strings_db   = clef FClef $ parts' .~ (ensemble !! 5) $ down (_P8^*3) $ stretch 16 strings_cue
strings_cue = delay (1/2) $ withTintin (down (_P8^*4) $ asPitch a) $ mainSubject

fallingScale :: [Score Note]
fallingScale = [a',g'..a_]

fallingScaleSect :: Int -> [Score Note]
fallingScaleSect n = {-fmap (annotate (show n)) $-} take n $ fallingScale

mainSubject :: Score Note
mainSubject = stretch (1/6) $ asScore $ scat $ mapEvensOdds (accent . (^*2)) id $ concatMap fallingScaleSect [1..30]

















mapEvensOdds :: (a -> b) -> (a -> b) -> [a] -> [b]
mapEvensOdds f g xs = let
    evens = fmap (xs !!) [0,2..]
    odds = fmap (xs !!) [1,3..]
    merge xs ys = concatMap (\(x,y) -> [x,y]) $ xs `zip` ys
    in take (length xs) $ map f evens `merge` map g odds


openAudacity :: Score Note -> IO ()    
openAudacity x = do
    -- void $ writeMidi "test.mid" $ x
    void $ system "timidity -Ow test.mid"
    void $ system "open -a Audacity test.wav"

openAudio :: Score Note -> IO ()    
openAudio x = do
    -- void $ writeMidi "test.mid" $ x
    void $ system "timidity -Ow test.mid"
    void $ system "open -a Audacity test.wav"

fixClefs :: Score Note -> Score Note
fixClefs = id
-- fixClefs = pcat . fmap (uncurry g) . extractParts'
--     where
--         g p x = clef (case defaultClef p of { 0 -> GClef; 1 -> CClef; 2 -> FClef } ) x

concurrently_ :: IO a -> IO b -> IO ()
concurrently_ = concurrentlyWith (\x y -> ())

concurrentlyWith :: (a -> b -> c) -> IO a -> IO b -> IO c
concurrentlyWith f x y = uncurry f <$> x `concurrently` y

play, open, openAndPlay :: Score Note -> IO ()   
tempo_ = 120
play x = openAudio $ stretch ((60*4)/tempo_) $ fixClefs $ x
open x = openLilypond' LyScoreFormat $ fixClefs $ x
openAndPlay x = play x `concurrently_` open x

