{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeFamilies #-}
{-|
This module is mainly intended to be used for rare occassions.
"Nero.Request" and "Nero.Payload" should provide everything you need
for HTTP parameters.
-}
module Nero.Param
  (
  -- * HTTP Parameters
    Param(..)
  -- * MultiMap
  , MultiMap
  , fromList
  , encodeMultiMap
  ) where

import Data.ByteString.Lazy (ByteString)
import qualified Data.ByteString.Lazy.Char8 as B8
import Data.Text.Lazy (Text, intercalate)
import Data.Map (Map)
import qualified Data.Map as Map
import Data.Text.Lazy.Lens (utf8)

import Nero.Prelude

-- * HTTP Parameters

-- | A 'Traversal'' of the values of a given HTTP parameter.
class Param a where
    param :: Text -> Traversal' a Text

-- * MultiMap

-- | A 'Map' with multiple values. Also known as a @MultiDict@ in most web
--   frameworks.
newtype MultiMap = MultiMap { unMultiMap :: Map Text [Text] }
                   deriving (Eq)

instance Show MultiMap where
    show = B8.unpack . encodeMultiMap

-- | The default monoid implementation is left biased, this implementation
--   /mappends/ the values.
instance Monoid MultiMap where
    mappend (MultiMap m1) (MultiMap m2) =
        MultiMap $ Map.unionWith mappend m1 m2
    mempty = MultiMap mempty

instance Wrapped MultiMap where
    type Unwrapped MultiMap = Map Text [Text]
    _Wrapped' = iso unMultiMap MultiMap

type instance Index MultiMap = Text
type instance IxValue MultiMap = [Text]
instance Ixed MultiMap where
    ix k = _Wrapped' . ix k

instance At MultiMap where
    at k = _Wrapped' . at k

instance Param MultiMap where
    param k = ix k . traverse

fromList :: [(Text, [Text])] -> MultiMap
fromList = MultiMap . Map.fromListWith (++)

-- | Encode a 'MultiMap' with the typical query string format. This is
--   useful to render 'MultiMap's when testing. The web server adapter for
--   @Nero@ should do this for you in the real application.
encodeMultiMap :: MultiMap -> ByteString
encodeMultiMap =
    review utf8
  . intercalate "&"
  -- Map.foldMapWithKey not supported in `containers-0.5.0.0` coming with
  -- GHC==7.6.3
  . fold . Map.mapWithKey (map . mappend . flip mappend "=")
  . unMultiMap
