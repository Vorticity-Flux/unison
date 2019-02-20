{-# LANGUAGE DeriveFoldable #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveTraversable #-}

module Unison.Kind where

import           GHC.Generics
import           Prelude.Extras                 ( Eq1(..)
                                                , Show1(..)
                                                )
import qualified Unison.ABT                    as ABT
import qualified Unison.Hashable               as Hashable
import           Unison.Hashable                ( Hashable1 )

data F a
  = Type
  | Arrow a a
  | Forall a
  deriving (Foldable, Functor, Generic, Generic1, Traversable)

type AnnotatedKind v a = ABT.Term F v a

instance Hashable1 F where
  hash1 _hashCycle hash e =
    -- Note: start each layer with leading `2` byte, to avoid collisions with
    -- terms and types which start each layer with leading `1` and `0`,
    -- respectively.
    let
      (tag, hashed) = (Hashable.Tag, Hashable.Hashed)
     in Hashable.accumulate $ tag 2 :
          case e of
            Type -> [tag 0]
            Arrow a b -> [tag 1, hashed $ hash a, hashed $ hash b]
            Forall a -> [tag 2, hashed $ hash a]

instance Show a => Show (F a) where
  showsPrec p fa = go p fa
   where
    go _ Type = showsPrec 0 "*"
    go p (Arrow i o) =
      showParen (p > 0) $ showsPrec (p + 1) i <> s " -> " <> showsPrec p o
    go p (Forall body) = case p of
      0 -> showsPrec p body
      _ -> showParen True $ s "∀ " <> showsPrec 0 body
    (<>) = (.)
    s    = showString

instance Eq1 F where (==#) = (==)
instance Show1 F where showsPrec1 = showsPrec
instance Eq a => Eq (F a) where
  Type == Type = True
  Arrow i o == Arrow i2 o2 = i == i2 && o == o2
  Forall a == Forall b = a == b
  _ == _ = False
