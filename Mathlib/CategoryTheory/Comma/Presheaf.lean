/-
Copyright (c) 2024 Markus Himmel. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Markus Himmel
-/
import Mathlib.CategoryTheory.Comma.Over
import Mathlib.Tactic.CategoryTheory.Elementwise

/-!
# Computation of `Over A` for a presheaf `A`

Let `A : Cᵒᵖ ⥤ Type v` be a presheaf. In this file, we construct an equivalence
`e : Over A ≌ (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v` and show that there is a quasi-commutative
diagram

```
CostructuredArrow yoneda A      ⥤      Over A

                             ⇘           ⥥

                               PSh(CostructuredArrow yoneda A)
```

where the top arrow is the forgetful functor forgetting the yoneda-costructure, the right arrow is
the aforementioned equivalence and the diagonal arrow is the Yoneda embedding.

In the notation of Kashiwara-Schapira, the type of the equivalence is written `C^ₐ ≌ Cₐ^`, where
`·ₐ` is `CostructuredArrow` (with the functor `S` being either the identity or the Yonenda
embedding) and `^` is taking presheaves. The equivalence is a key ingredient in various results in
Kashiwara-Schapira.

The proof is somewhat long and technical, in part due to the construction inherently involving a
sigma type which comes with the usual DTT issues. However, a user of this result should not need
to interact with the actual construction, the mere existence of the equivalence and the commutative
triangle should generally be sufficient.

## Main results
* `OverEquivPresheafCostructuredArrow`:
  the equivalence `Over A ≌ (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v`
* `CostructuredArrow.toOverCompOverEquivPresheafCostructuredArrow`: the natural isomorphism
  `CostructuredArrow.toOver yoneda A ⋙ (OverEquivPresheafCostructuredArrow A).functor ≅ yoneda`

## Implementation details



## Future work
* If needed, it should be possible to show that the equivalence is natural in `A`.

## References
* [M. Kashiwara, P. Schapira, *Categories and Sheaves*][Kashiwara2006], Lemma 1.4.12

## Tags
presheaf, over category, coyoneda

-/

namespace CategoryTheory

open Category Opposite

universe w v u

variable {C : Type u} [Category.{v} C] {A : Cᵒᵖ ⥤ Type v}

namespace OverPresheafAux

structure IsYonedaPreimage {F : Cᵒᵖ ⥤ Type v} (η : F ⟶ A) {X : C} (s : yoneda.obj X ⟶ A)
    (u : F.obj (op X)) : Prop where
  (app : η.app (op X) u = yonedaEquiv s)

lemma IsYonedaPreimage.map₁ {F G : Cᵒᵖ ⥤ Type v} {η : F ⟶ A} {μ : G ⟶ A} {ε : F ⟶ G} (hε : ε ≫ μ = η)
    {X : C} {s : yoneda.obj X ⟶ A} {u : F.obj (op X)} (h : IsYonedaPreimage η s u) :
    IsYonedaPreimage μ s (ε.app _ u) :=
  ⟨by rw [← elementwise_of% NatTrans.comp_app ε μ, hε, h.app]⟩

lemma IsYonedaPreimage.map₂ {F : Cᵒᵖ ⥤ Type v} {η : F ⟶ A} {X Y : C} (f : X ⟶ Y)
    {s : yoneda.obj X ⟶ A} {t : yoneda.obj Y ⟶ A} (hst : yoneda.map f ≫ t = s)
    {u : F.obj (op Y)} (h : IsYonedaPreimage η t u) : IsYonedaPreimage η s (F.map f.op u) :=
  ⟨by rw [elementwise_of% η.naturality, h.app, yonedaEquiv_naturality, hst]⟩

def YonedaPreimage {F : Cᵒᵖ ⥤ Type v} (η : F ⟶ A) {X : C} (s : yoneda.obj X ⟶ A) : Type v :=
  Subtype (IsYonedaPreimage η s)

def YonedaPreimage.val {F : Cᵒᵖ ⥤ Type v} {η : F ⟶ A} {X : C} {s : yoneda.obj X ⟶ A} :
    YonedaPreimage η s → F.obj (op X) :=
  Subtype.val

@[ext]
lemma YonedaPreimage.ext {F : Cᵒᵖ ⥤ Type v} {η : F ⟶ A} {X : C} {s : yoneda.obj X ⟶ A}
    {u v : YonedaPreimage η s} : u.val = v.val → u = v :=
  Subtype.ext

lemma YonedaPreimage.app_val {F : Cᵒᵖ ⥤ Type v} {η : F ⟶ A} {X : C} {s : yoneda.obj X ⟶ A}
    (p : YonedaPreimage η s) : η.app _ p.val = yonedaEquiv s :=
  p.prop.app

-- def YonedaPreimage.mk {F A : Cᵒᵖ ⥤ Type v} {η : F ⟶ A} {X : C} {s : yoneda.obj X ⟶ A} (u : F.obj (op X)) (hu : η.app _ u = yonedaEquiv s) : YonedaPreimage η s :=
--   ⟨u, ⟨hu⟩⟩

-- attribute [irreducible] YonedaPreimage

@[simp]
lemma YonedaPreimage.map_val {Y : C} {η : yoneda.obj Y ⟶ A} {X : C} {s : yoneda.obj X ⟶ A}
    (p : YonedaPreimage η s) : yoneda.map p.val ≫ η = s := by
  apply yonedaEquiv.injective
  simp [yonedaEquiv_apply, yonedaEquiv_comp, yonedaEquiv_yoneda_map, p.app_val, op_unop]

def YonedaPreimage.map₁ {F G : Cᵒᵖ ⥤ Type v} {η : F ⟶ A} {μ : G ⟶ A} {X : C}
    {s : yoneda.obj X ⟶ A} (u : YonedaPreimage η s) (ε : F ⟶ G) (hε : ε ≫ μ = η) :
    YonedaPreimage μ s :=
  ⟨ε.app _ u.val, IsYonedaPreimage.map₁ hε u.2⟩

@[simp]
lemma YonedaPreimage.map₁_val {F G : Cᵒᵖ ⥤ Type v} {η : F ⟶ A} {μ : G ⟶ A} {X : C}
    (s : yoneda.obj X ⟶ A) (u : YonedaPreimage η s) (ε : F ⟶ G) (hε : ε ≫ μ = η) :
    (u.map₁ ε hε).val = ε.app _ u.val :=
  rfl

def YonedaPreimage.map₂ {F : Cᵒᵖ ⥤ Type v} {η : F ⟶ A} {X Y : C} {s : yoneda.obj X ⟶ A}
  {t : yoneda.obj Y ⟶ A} (u : YonedaPreimage η t) (f : X ⟶ Y) (hst : yoneda.map f ≫ t = s) :
    YonedaPreimage η s :=
  ⟨F.map f.op u.val, IsYonedaPreimage.map₂ f hst u.2⟩

@[simp]
lemma YonedaPreimage.map₂_val {F : Cᵒᵖ ⥤ Type v} {η : F ⟶ A} {X Y : C} (f : X ⟶ Y)
    {s : yoneda.obj X ⟶ A} {t : yoneda.obj Y ⟶ A} (hst : yoneda.map f ≫ t = s)
    (u : YonedaPreimage η t) : (u.map₂ f hst).val = F.map f.op u.val :=
  rfl

@[simp]
lemma YonedaPreimage_map₁_map₂ {F G : Cᵒᵖ ⥤ Type v} {η : F ⟶ A} {μ : G ⟶ A} (ε : F ⟶ G) (hε : ε ≫ μ = η) {X Y : C}
    {s : yoneda.obj X ⟶ A} {t : yoneda.obj Y ⟶ A}
    (f : X ⟶ Y) (hf : yoneda.map f ≫ t = s) (u : YonedaPreimage η t) :
    (u.map₁ ε hε).map₂ f hf = (u.map₂ f hf).map₁ ε hε :=
  YonedaPreimage.ext <| (elementwise_of% (ε.naturality f.op).symm) u.val

@[simps (config := { fullyApplied := false }) obj map]
def yonedaPreimageFunctor' {F : Cᵒᵖ ⥤ Type v} (η : F ⟶ A) : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v where
  obj s := YonedaPreimage η s.unop.hom
  map f u := u.map₂ f.unop.left f.unop.w

@[simps]
def yonedaPreimageFunctor'_map₁ {F G : Cᵒᵖ ⥤ Type v} {η : F ⟶ A} {μ : G ⟶ A} (ε : F ⟶ G) (hε : ε ≫ μ = η) :
    yonedaPreimageFunctor' η ⟶ yonedaPreimageFunctor' μ where
  app s u := u.map₁ ε hε

@[simps]
def yonedaPreimageFunctor (A : Cᵒᵖ ⥤ Type v) : Over A ⥤ (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v where
  obj η := yonedaPreimageFunctor' η.hom
  map ε := yonedaPreimageFunctor'_map₁ ε.left ε.w

def yonedaPreimageCostructuredArrow (A : Cᵒᵖ ⥤ Type v) (s t : CostructuredArrow yoneda A) :
    YonedaPreimage s.hom t.hom ≅ t ⟶ s :=
  ⟨fun p => CostructuredArrow.homMk p.val (by aesop_cat), fun f => ⟨f.left, ⟨by
    have := f.w
    dsimp at this
    rw [Category.comp_id] at this
    rw [← this, ← yonedaEquiv_naturality]
    dsimp [yonedaEquiv_apply]
    have := congrFun (s.hom.naturality f.left.op) (𝟙 s.left)
    dsimp at this
    rw [← this, Category.comp_id]
  ⟩⟩, by aesop_cat, by aesop_cat⟩

@[simps!]
def yonedaCompYonedaPreimageFunctor (A : Cᵒᵖ ⥤ Type v) :
    CostructuredArrow.toOver yoneda A ⋙ yonedaPreimageFunctor A ≅ yoneda :=
  NatIso.ofComponents (fun s => by
    refine' NatIso.ofComponents (fun t => yonedaPreimageCostructuredArrow _ _ _) _
    aesop_cat
  ) (by aesop_cat)

def YonedaCollection (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v) (X : C) :
    Type v :=
  Σ (s : A.obj (op X)), F.obj (op (CostructuredArrow.mk (yonedaEquiv.symm s)))

def YonedaCollection.mk {F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v}
    {X : C} (s : A.obj (op X)) (x : F.obj (op (CostructuredArrow.mk (yonedaEquiv.symm s)))) :
    YonedaCollection F X :=
  ⟨s, x⟩

def YonedaCollection.mk' {F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v}
    {X : C} (s : yoneda.obj X ⟶ A) (x : F.obj (op (CostructuredArrow.mk s))) :
    YonedaCollection F X := ⟨yonedaEquiv s, F.map (eqToHom <| by rw [Equiv.symm_apply_apply]) x⟩

def YonedaCollection.fst {F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v}
    {X : C} (p : YonedaCollection F X) : A.obj (op X) := p.1

def YonedaCollection.snd {F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v}
    {X : C} (p : YonedaCollection F X) :
    F.obj (op (CostructuredArrow.mk (yonedaEquiv.symm p.fst))) := p.2

def YonedaCollection.fst' {F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v}
    {X : C} (p : YonedaCollection F X) : yoneda.obj X ⟶ A :=
  yonedaEquiv.symm p.fst

def YonedaCollection.snd' {F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v}
    {X : C} (p : YonedaCollection F X) : F.obj (op (CostructuredArrow.mk p.fst')) :=
  p.snd

lemma YonedaCollection.fst_eq_yonedEquiv_fst'
    {F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v} {X : C} (p : YonedaCollection F X) :
    p.fst = yonedaEquiv p.fst' :=
  (Equiv.apply_symm_apply _ _).symm

@[simp]
lemma YonedaCollection.mk'_fst' {F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v}
    {X : C} (s : yoneda.obj X ⟶ A) (x : F.obj (op (CostructuredArrow.mk s))) :
    (YonedaCollection.mk' s x).fst' = s :=
  Equiv.apply_symm_apply _ _

@[simp]
lemma YonedaCollection.mk'_snd' {F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v}
    {X : C} (s : yoneda.obj X ⟶ A) (x : F.obj (op (CostructuredArrow.mk s))) :
    (YonedaCollection.mk' s x).snd' = F.map (eqToHom <| by rw [YonedaCollection.mk'_fst']) x := rfl

@[ext]
lemma YonedaCollection.ext' {F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v}
    {X : C} (p q : YonedaCollection F X) : (h : p.fst' = q.fst') → F.map (eqToHom <| by rw [h]) q.snd' = p.snd' → p = q := by
  -- TODO: Clean up this proof
  intro h h'
  rcases p with ⟨p, p'⟩
  rcases q with ⟨q, q'⟩
  obtain rfl : p = q := yonedaEquiv.symm.injective h
  apply Sigma.ext
  · rfl
  · rw [heq_eq_eq]
    convert h'.symm
    simp [snd']
    rfl

def YonedaCollection.map₁ {F G : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v}
    (η : F ⟶ G) {X : C} : YonedaCollection F X → YonedaCollection G X := fun p =>
  YonedaCollection.mk' p.fst' (η.app _ p.snd')

@[simp]
lemma YonedaCollection.map₁_fst' {F G : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v}
    (η : F ⟶ G) {X : C} (p : YonedaCollection F X) : (YonedaCollection.map₁ η p).fst' = p.fst' := by
  simp [map₁]

@[simp]
lemma YonedaCollection.map₁_snd' {F G : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v}
    (η : F ⟶ G) {X : C} (p : YonedaCollection F X) :
    (YonedaCollection.map₁ η p).snd' = G.map (eqToHom (by rw [YonedaCollection.map₁_fst'])) (η.app _ p.snd') := by
  simp [map₁]

@[simp]
lemma YonedaCollection.map₁_fst {F G : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v}
    (η : F ⟶ G) {X : C} (p : YonedaCollection F X) :
    (YonedaCollection.map₁ η p).fst = p.fst := by
  simp only [YonedaCollection.fst_eq_yonedEquiv_fst', map₁_fst']

def YonedaCollection.map₂ (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v) {X Y : C}
    (f : X ⟶ Y) : YonedaCollection F Y → YonedaCollection F X := fun p =>
  YonedaCollection.mk' (yoneda.map f ≫ p.fst') $ F.map (Quiver.Hom.op (CostructuredArrow.homMk'' p.fst' f)) p.snd'

@[simp]
lemma YonedaCollection.map₂_fst' (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v) {X Y : C}
    (f : X ⟶ Y) (p : YonedaCollection F Y) :
    (YonedaCollection.map₂ F f p).fst' = yoneda.map f ≫ p.fst' :=
  by simp [map₂]

@[simp]
lemma YonedaCollection.map₂_fst (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v) {X Y : C}
    (f : X ⟶ Y) (p : YonedaCollection F Y) :
    (YonedaCollection.map₂ F f p).fst = A.map f.op p.fst := by
  simp only [YonedaCollection.fst_eq_yonedEquiv_fst', map₂_fst', yonedaEquiv_naturality]

@[simp]
lemma YonedaCollection.map₂_snd' (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v) {X Y : C}
    (f : X ⟶ Y) (p : YonedaCollection F Y) :
    (YonedaCollection.map₂ F f p).snd' = F.map (Quiver.Hom.op (CostructuredArrow.homMk'' p.fst' f) ≫ eqToHom (by rw [YonedaCollection.map₂_fst' F f])) p.snd' := by
  simp [map₂]

@[simp]
lemma bla {F : C ⥤ Type w} {X Y Z : C} (h₁ : X = Y) (h₂ : Y = Z) (x : F.obj X) :
  F.map (eqToHom h₂) (F.map (eqToHom h₁) x) = F.map (eqToHom (h₁.trans h₂)) x :=
  by aesop_cat

attribute [simp] CostructuredArrow.homMk''_id

@[simp]
lemma YonedaCollection.map₂_id {A : Cᵒᵖ ⥤ Type v} {F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v} {X : C} :
    YonedaCollection.map₂ F (𝟙 X) = id := by
  ext p
  · simp
  · simp

-- How does simp even know how to apply this
@[simp]
lemma blubb {F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v} {X Y : C} {f : X ⟶ Y}
    {g g' : yoneda.obj Y ⟶ A} (h : g = g') {x : F.obj (op (CostructuredArrow.mk g'))} :
  F.map (CostructuredArrow.homMk'' g f).op (F.map (eqToHom (by rw [h])) x) = F.map (eqToHom (by rw [h])) (F.map (CostructuredArrow.homMk'' g' f).op x)
   := by aesop_cat

attribute [simp] CostructuredArrow.homMk''_comp

@[simp]
lemma YonedaCollection.map₂_comp {F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v} {X Y Z : C}
    (f : X ⟶ Y) (g : Y ⟶ Z) : YonedaCollection.map₂ F (f ≫ g) = YonedaCollection.map₂ F f ∘ YonedaCollection.map₂ F g := by
  ext p
  · simp
  · simp

@[simp]
lemma YonedaCollection.map₁_map₂ {F G : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v}
  (η : F ⟶ G) {X Y : C} (f : X ⟶ Y) (p : YonedaCollection F Y) :
    YonedaCollection.map₂ G f (YonedaCollection.map₁ η p) = YonedaCollection.map₁ η (YonedaCollection.map₂ F f p) := by
  ext
  · simp
  · simp [FunctorToTypes.naturality]

@[simp]
lemma YonedaCollection.map₁_id {F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v} {X : C} :
  YonedaCollection.map₁ (𝟙 F) (X := X) = id := by aesop_cat

@[simp]
lemma YonedaCollection.map₁_comp {F G H : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v}
    (η : F ⟶ G) (μ : G ⟶ H) {X : C} :
    YonedaCollection.map₁ (η ≫ μ) (X := X) = YonedaCollection.map₁ μ (X := X) ∘ YonedaCollection.map₁ η (X := X) := by
  ext
  · simp
  · simp [FunctorToTypes.naturality]

@[simps (config := { fullyApplied := false })]
def YonedaCollectionFunctor' (A : Cᵒᵖ ⥤ Type v) (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v) :
    Cᵒᵖ ⥤ Type v where
  obj X := YonedaCollection F X.unop
  map f := YonedaCollection.map₂ F f.unop

@[simps]
def YonedaCollectionMap {F G : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v} (η : F ⟶ G) :
    YonedaCollectionFunctor' A F ⟶ YonedaCollectionFunctor' A G where
  app X := YonedaCollection.map₁ η
  naturality := by
    intros
    ext
    simp

@[simps (config := { fullyApplied := false }) obj map]
def YonedaCollectionFunctor (A : Cᵒᵖ ⥤ Type v) : ((CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v) ⥤ Cᵒᵖ ⥤ Type v where
  obj := YonedaCollectionFunctor' A
  map η := YonedaCollectionMap η

@[simps (config := { fullyApplied := false }) app]
def YonedaCollectionFunctorToA (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v) :
    YonedaCollectionFunctor' A F ⟶ A where
  app X := YonedaCollection.fst

@[simps! (config := { fullyApplied := false }) obj map]
def YonedaCollectionTotal (A : Cᵒᵖ ⥤ Type v) :
    ((CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v) ⥤ Over A :=
  (YonedaCollectionFunctor A).toOver _ (YonedaCollectionFunctorToA) (by aesop_cat)

def ax {F : Cᵒᵖ ⥤ Type v} (η : F ⟶ A) (X : C) :
    YonedaCollection (yonedaPreimageFunctor' η) X → F.obj (op X) :=
  fun p => p.snd'.val

@[simp]
lemma ax_naturality₁ {F G : Cᵒᵖ ⥤ Type v} {η : F ⟶ A} {μ : G ⟶ A} (ε : F ⟶ G) (hε : ε ≫ μ = η) (X : C) (p : YonedaCollection (yonedaPreimageFunctor' η) X) :
    ax μ X (p.map₁ (yonedaPreimageFunctor'_map₁ ε hε)) = ε.app _ (ax η X p) := by
  simp [ax]

@[simp]
lemma ax_naturality₂ {F : Cᵒᵖ ⥤ Type v} (η : F ⟶ A) (X Y : C) (f : X ⟶ Y) (p : YonedaCollection (yonedaPreimageFunctor' η) Y) :
    ax η X (YonedaCollection.map₂ (yonedaPreimageFunctor' η) f p) = F.map f.op (ax η Y p) := by
  simp [ax]

@[simp]
lemma app_ax {F : Cᵒᵖ ⥤ Type v} (η : F ⟶ A) (X : Cᵒᵖ) (p : YonedaCollection (yonedaPreimageFunctor' η) X.unop) :
    η.app X (ax η X.unop p) = p.fst := by
  simp [ax]
  have := p.snd'.app_val
  dsimp  at this
  simp [ this, YonedaCollection.fst_eq_yonedEquiv_fst']

def back {F : Cᵒᵖ ⥤ Type v} (η : F ⟶ A) (X : C) :
    F.obj (op X) → YonedaCollection (yonedaPreimageFunctor' η) X :=
  fun x => YonedaCollection.mk' (yonedaEquiv.symm (η.app _ x)) ⟨x, ⟨by aesop_cat⟩⟩

lemma ax_back {F : Cᵒᵖ ⥤ Type v} (η : F ⟶ A) (X : C) : ax η X ∘ back η X = id := by
  ext x
  dsimp [ax, back]
  aesop_cat

lemma back_ax {F : Cᵒᵖ ⥤ Type v} (η : F ⟶ A) (X : C) : back η X ∘ ax η X = id := by
  ext1 p
  simp [ax, back]
  refine' YonedaCollection.ext' _ _ _ _
  · have := p.snd'.app_val
    dsimp at this
    dsimp
    simp [this]
  · apply YonedaPreimage.ext
    aesop_cat

@[simps]
def bij {F : Cᵒᵖ ⥤ Type v} (η : F ⟶ A) (X : C) :
    YonedaCollection (yonedaPreimageFunctor' η) X ≅ F.obj (op X) where
  hom := ax η X
  inv := back η X
  hom_inv_id := back_ax η X
  inv_hom_id := ax_back η X

@[simps!]
def unit₀ {F : Cᵒᵖ ⥤ Type v} (η : F ⟶ A) : YonedaCollectionFunctor' A (yonedaPreimageFunctor' η) ≅ F :=
  NatIso.ofComponents (fun X => bij η X.unop) (by aesop_cat)

@[simps!]
def unit_pt (η : Over A) : (yonedaPreimageFunctor A ⋙ YonedaCollectionTotal A).obj η ≅ η :=
  Over.isoMk (unit₀ η.hom) (by aesop_cat)

def unit (A : Cᵒᵖ ⥤ Type v) : yonedaPreimageFunctor A ⋙ YonedaCollectionTotal A ≅ 𝟭 (Over A) :=
  NatIso.ofComponents unit_pt (by aesop_cat)

@[simp]
lemma val_fst' (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v) (X : C)
    (s : yoneda.obj X ⟶ A) (p : YonedaPreimage (YonedaCollectionFunctorToA F) s) : p.val.fst' = s := by
  simpa [YonedaCollection.fst_eq_yonedEquiv_fst'] using p.app_val

def cofo (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v) (s : CostructuredArrow yoneda A) :
    F.obj (op s) → YonedaPreimage (YonedaCollectionFunctorToA F) s.hom :=
  fun x => ⟨YonedaCollection.mk' s.hom x, ⟨by simp [YonedaCollection.fst_eq_yonedEquiv_fst']⟩⟩

@[simp]
lemma cofo_naturality₁ {F G : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v} (η : F ⟶ G)
    (s : (CostructuredArrow yoneda A)ᵒᵖ) (x : F.obj s) : cofo G s.unop (η.app s x) = YonedaPreimage.map₁ (cofo F s.unop x) (YonedaCollectionMap η) (by aesop_cat) := by
  dsimp [cofo]
  apply YonedaPreimage.ext
  simp
  refine' YonedaCollection.ext' _ _ _ _
  · simp
  · simp
    erw [YonedaCollection.mk'_snd']
    erw [YonedaCollection.mk'_snd']
    exact FunctorToTypes.naturality _ _ _ _ _

lemma bloink (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v) (s t : CostructuredArrow yoneda A)
    (f : s ⟶ t) (x : F.obj (op t)) : (F.map (CostructuredArrow.homMk'' t.hom f.left).op x) = F.map (eqToHom <| by simp [← CostructuredArrow.eq_mk]) (F.map f.op x) := by
  have : (CostructuredArrow.homMk'' t.hom f.left).op = f.op ≫ eqToHom (by simp [← CostructuredArrow.eq_mk]) := by
    apply Quiver.Hom.unop_inj
    aesop_cat
  erw [this]
  simp

@[simp]
lemma cofo_naturality₂ (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v) (s t : (CostructuredArrow yoneda A)ᵒᵖ)
    (f : t ⟶ s) (x : F.obj t) : cofo F s.unop (F.map f x) = YonedaPreimage.map₂ (cofo F t.unop x) f.unop.left (by simp) := by
  simp [cofo]
  apply YonedaPreimage.ext
  rw [YonedaPreimage.map₂_val]
  refine' YonedaCollection.ext' _ _ _ _
  · simp only [Opposite.unop_op, YonedaCollectionFunctor'_obj, val_fst',
    YonedaCollectionFunctor'_map, Quiver.Hom.unop_op, YonedaCollection.map₂_fst', CommaMorphism.w,
    Functor.const_obj_obj, CostructuredArrow.right_eq_id, Functor.const_obj_map, comp_id]
  · erw [YonedaCollection.mk'_snd']
    erw [YonedaCollection.mk'_snd']
    erw [YonedaCollection.mk'_snd']
    simp only [Opposite.unop_op, YonedaCollectionFunctor'_obj, YonedaCollectionFunctor'_map,
      Quiver.Hom.unop_op, id_eq, eq_mpr_eq_cast, val_fst', blubb, bla]
    erw [bloink]
    simp

def coba (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v) (s : CostructuredArrow yoneda A) :
    YonedaPreimage (YonedaCollectionFunctorToA F) s.hom → F.obj (op s) :=
  fun p => F.map (eqToHom (by simp [val_fst', ← CostructuredArrow.eq_mk])) p.val.snd'

lemma cofo_coba {A : Cᵒᵖ ⥤ Type v} (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v) (s : CostructuredArrow yoneda A) :
    cofo F s ∘ coba F s = id := by
  ext p
  dsimp [cofo, coba]
  change YonedaCollection.mk' _ _ = _
  refine' YonedaCollection.ext' _ _ _ _
  · simp
  · simp

lemma coba_cofo (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v) (s : CostructuredArrow yoneda A) :
    coba F s ∘ cofo F s = id := by
  ext x
  dsimp [cofo, coba]
  erw [YonedaCollection.mk'_snd']
  simp

@[simps]
def cobij (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v) (s : CostructuredArrow yoneda A) :
    F.obj (op s) ≅ YonedaPreimage (YonedaCollectionFunctorToA F) s.hom where
  hom := cofo F s
  inv := coba F s
  hom_inv_id := coba_cofo F s
  inv_hom_id := cofo_coba F s

@[simps! (config := { fullyApplied := false }) hom]
def counit₀ (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v) :
    F ≅ yonedaPreimageFunctor' (YonedaCollectionFunctorToA F) :=
  NatIso.ofComponents (fun s => cobij F s.unop) (by aesop_cat)

def counit (A : Cᵒᵖ ⥤ Type v) : 𝟭 ((CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v) ≅ (YonedaCollectionTotal A ⋙ yonedaPreimageFunctor A) :=
  NatIso.ofComponents counit₀ (by aesop_cat)

end OverPresheafAux

/-- If `A : Cᵒᵖ ⥤ Type v` is a presheaf, then we have an equivalence between presheaves lying over
    `A` and the category of presheaves on `CostructuredArrow yoneda A`. There is a quasicommutative
    triangle involving this equivalence, see
    `CostructuredArrow.toOverCompOverEquivPresheafCostructuredArrow`.

    This is Lemma 1.4.12 in [Kashiwara2006]. -/
def OverEquivPresheafCostructuredArrow (A : Cᵒᵖ ⥤ Type v) :
    Over A ≌ ((CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v) :=
  Equivalence.mk (OverPresheafAux.yonedaPreimageFunctor A) (OverPresheafAux.YonedaCollectionTotal A)
    (OverPresheafAux.unit A).symm (OverPresheafAux.counit A).symm

/-- If `A : Cᵒᵖ ⥤ Type v` is a presheaf, then the Yoneda embedding for
    `CostructuredArrow yoneda A` factors through `Over A` via a forgetful functor and an
    equivalence.

    This is Lemma 1.4.12 in [Kashiwara2006]. -/
def CostructuredArrow.toOverCompOverEquivPresheafCostructuredArrow (A : Cᵒᵖ ⥤ Type v) :
    CostructuredArrow.toOver yoneda A ⋙ (OverEquivPresheafCostructuredArrow A).functor ≅ yoneda :=
  OverPresheafAux.yonedaCompYonedaPreimageFunctor A

end CategoryTheory
