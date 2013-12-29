
import System.Process (runCommand)
import Music.Prelude.Basic

main = do
    -- writeMidi "test.mid" score
    -- writeXml "test.xml" $ score^/4
    -- openXml score
    openLy score
    -- playMidiIO "Graphic MIDI" $ score^/10

score :: Score Note
score = let
        triplet = group 3
        rest = return Nothing

        a `x` b = a^*(3/4) |> b^*(1/4)
        a `l` b = (a |> b)^/2
    
        motive = (legato $ stretchTo 2 $ scat [g,a,bb,c',d',eb']) |> staccato (d' |> bb |> g)
        bar    = rest^*4 :: Score (Maybe Note)

        song    = mempty
        left    = times 4 (times 4 $ removeRests $ triplet g)
        right   = removeRests $ times 2 (delay 4 motive |> rest^*3)

        -- Use 4/4 or 12/8 notation
        useCommonTime = True
        scale         = if useCommonTime then id else timeSignature (time 12 8) . stretch (3/2) 

    in scale $ stretch (1/4) $ song </> left </> down _P8 right