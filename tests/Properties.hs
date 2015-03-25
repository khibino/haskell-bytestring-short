{-# OPTIONS_GHC -fno-warn-orphans #-}

import Data.ByteString.Char8 ()
import qualified Data.ByteString            as P
import qualified Data.ByteString.Internal   as P
import qualified Data.ByteString.Short      as Short

import Control.Applicative ((<$>))
import Control.Monad (unless)
import Data.Monoid (mappend, mconcat)
import Data.Maybe (catMaybes)
import Data.String (fromString)
import System.IO (stderr, hPutStrLn)
import Test.QuickCheck
  (Testable, Property, Result (..), quickCheckResult, label,
  Arbitrary (..), choose)


type Test = (String, Property)

testProperty :: Testable prop => String -> prop -> Test
testProperty m = (,) m . label m

runMayError :: Testable prop => (a, prop) -> IO (Maybe (a, Result))
runMayError (m, prop) = fmap ((,) m) . err <$> quickCheckResult prop  where
  err :: Result -> Maybe Result
  err (Success {})  =  Nothing
  err x             =  Just x

defaultMain :: [Test] -> IO ()
defaultMain xs = do
  es <- catMaybes <$> mapM runMayError xs
  mapM_ (\(m, r) -> hPutStrLn stderr $ m ++ ":\n" ++ show r) es
  unless (null es) $ fail "Found some failures."

main :: IO ()
main = defaultMain tests


-- Arbitrary instance for only test.
instance Arbitrary P.ByteString where
  arbitrary = do
    bs <- P.pack `fmap` arbitrary
    n  <- choose (0, 2)
    return (P.drop n bs) -- to give us some with non-0 offset

prop_short_pack_unpack xs =
    (Short.unpack . Short.pack) xs == xs
prop_short_toShort_fromShort bs =
    (Short.fromShort . Short.toShort) bs == bs

prop_short_toShort_unpack bs =
    (Short.unpack . Short.toShort) bs == P.unpack bs
prop_short_pack_fromShort xs =
    (Short.fromShort . Short.pack) xs == P.pack xs

prop_short_empty =
    Short.empty == Short.toShort P.empty
 && Short.empty == Short.pack []
 && Short.null (Short.toShort P.empty)
 && Short.null (Short.pack [])
 && Short.null Short.empty

prop_short_null_toShort bs =
    P.null bs == Short.null (Short.toShort bs)
prop_short_null_pack xs =
    null xs == Short.null (Short.pack xs)

prop_short_length_toShort bs =
    P.length bs == Short.length (Short.toShort bs)
prop_short_length_pack xs =
    length xs == Short.length (Short.pack xs)

prop_short_index_pack xs =
    all (\i -> Short.pack xs `Short.index` i == xs !! i)
        [0 .. length xs - 1]
prop_short_index_toShort bs =
    all (\i -> Short.toShort bs `Short.index` i == bs `P.index` i)
        [0 .. P.length bs - 1]

prop_short_eq xs ys =
    (xs == ys) == (Short.pack xs == Short.pack ys)
prop_short_ord xs ys =
    (xs `compare` ys) == (Short.pack xs `compare` Short.pack ys)

prop_short_mappend_empty_empty =
    Short.empty `mappend` Short.empty  == Short.empty
prop_short_mappend_empty xs =
    Short.empty `mappend` Short.pack xs == Short.pack xs
 && Short.pack xs `mappend` Short.empty == Short.pack xs
prop_short_mappend xs ys =
    (xs `mappend` ys) == Short.unpack (Short.pack xs `mappend` Short.pack ys)
prop_short_mconcat xss =
    mconcat xss == Short.unpack (mconcat (map Short.pack xss))

prop_short_fromString s =
    fromString s == Short.fromShort (fromString s)

prop_short_show xs =
    show (Short.pack xs) == show (map P.w2c xs)
prop_short_show' xs =
    show (Short.pack xs) == show (P.pack xs)

prop_short_read xs =
    read (show (Short.pack xs)) == Short.pack xs

tests :: [Test]
tests =
    [ testProperty "pack/unpack"              prop_short_pack_unpack
    , testProperty "toShort/fromShort"        prop_short_toShort_fromShort
    , testProperty "toShort/unpack"           prop_short_toShort_unpack
    , testProperty "pack/fromShort"           prop_short_pack_fromShort
    , testProperty "empty"                    prop_short_empty
    , testProperty "null/toShort"             prop_short_null_toShort
    , testProperty "null/pack"                prop_short_null_pack
    , testProperty "length/toShort"           prop_short_length_toShort
    , testProperty "length/pack"              prop_short_length_pack
    , testProperty "index/pack"               prop_short_index_pack
    , testProperty "index/toShort"            prop_short_index_toShort
    , testProperty "Eq"                       prop_short_eq
    , testProperty "Ord"                      prop_short_ord
    , testProperty "mappend/empty/empty"      prop_short_mappend_empty_empty
    , testProperty "mappend/empty"            prop_short_mappend_empty
    , testProperty "mappend"                  prop_short_mappend
    , testProperty "mconcat"                  prop_short_mconcat
    , testProperty "fromString"               prop_short_fromString
    , testProperty "show"                     prop_short_show
    , testProperty "show'"                    prop_short_show'
    , testProperty "read"                     prop_short_read
    ]
