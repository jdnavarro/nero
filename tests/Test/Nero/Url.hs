{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RankNTypes #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Test.Nero.Url (tests) where

import Data.Text.Lazy (Text)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.SmallCheck.Lens (testLens, testTraversal)
import Test.SmallCheck.Series (Serial, CoSerial)
import Test.SmallCheck.Series.Instances ()
import Test.Tasty.HUnit

import Nero.Prelude
import Nero.Param
import Nero.Binary (render)

import Nero.Url

instance (Serial m a) => Serial m (NonEmpty a)
instance (CoSerial m a) => CoSerial m (NonEmpty a)
instance (Serial m a) => Serial m (Values a)
instance (CoSerial m a) => CoSerial m (Values a)

instance Monad m => Serial m Scheme

instance Monad m => Serial m Query

instance Monad m => CoSerial m Query

instance Monad m => Serial m Url

tests :: TestTree
tests = testGroup "Url"
  [ testLens (host  :: Lens' Url Host)
  , testLens (query :: Lens' Url Query)
  , testLens (path  :: Lens' Url Path)
  , testTraversal (param "aaa" :: Traversal' Url Text)
  , testTraversal (param "bbb" :: Traversal' Url Text)
  , testTraversal (param "" :: Traversal' Url Text)
  , testRenderUrl
  ]

testRenderUrl :: TestTree
testRenderUrl = testGroup "Render"
  [ testCase "empty" $ "http://" @=? render defaultUrl
  , testCase "Example.com" $
      "http://example.com" @=? render (defaultUrl & host .~ "example.com")
  , testCase "single key" $ "http://example.com?query" @=?
      render (defaultUrl & host  .~ "example.com" 
                         & query . at "query" ?~ mempty)
  , testCase "single key with empty value" $ "http://example.com?query=" @=?
      render (defaultUrl & host  .~ "example.com" 
                         & query . at "query" ?~ pure mempty)
  , testCase "One key/value" $ "http://example.com?query=value" @=?
      render (defaultUrl & host .~ "example.com"
                         & query . at "query" ?~ "value")
  , testCase "One key, multiple values" $ "http://example.com?query=value1&query=value2" @=?
      render (defaultUrl & host .~ "example.com"
                         & query . at "query" ?~ ("value1" <> "value2"))
  , testCase "Multiple key/value pairs" $ "http://example.com?key1=value1&key2=value2" @=?
      render (defaultUrl & host .~ "example.com"
                         & query . at "key1" ?~ "value1"
                         & query . at "key2" ?~ "value2")
  ]
