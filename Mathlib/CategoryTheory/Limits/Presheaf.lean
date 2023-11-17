/-
Copyright (c) 2020 Bhavik Mehta. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Bhavik Mehta
-/
import Mathlib.CategoryTheory.Adjunction.Limits
import Mathlib.CategoryTheory.Adjunction.Opposites
import Mathlib.CategoryTheory.Elements
import Mathlib.CategoryTheory.Limits.ConeCategory
import Mathlib.CategoryTheory.Limits.Final
import Mathlib.CategoryTheory.Limits.FunctorCategory
import Mathlib.CategoryTheory.Limits.KanExtension
import Mathlib.CategoryTheory.Limits.Shapes.Terminal
import Mathlib.CategoryTheory.Limits.Shapes.Products
import Mathlib.CategoryTheory.Limits.Shapes.Types
import Mathlib.CategoryTheory.Limits.Over
import Mathlib.CategoryTheory.Limits.EssentiallySmall

#align_import category_theory.limits.presheaf from "leanprover-community/mathlib"@"70fd9563a21e7b963887c9360bd29b2393e6225a"

/-!
# Colimit of representables

This file constructs an adjunction `yonedaAdjunction` between `(Cᵒᵖ ⥤ Type u)` and `ℰ` given a
functor `A : C ⥤ ℰ`, where the right adjoint sends `(E : ℰ)` to `c ↦ (A.obj c ⟶ E)` (provided `ℰ`
has colimits).

This adjunction is used to show that every presheaf is a colimit of representables. This result is
also known as the density theorem, the co-Yoneda lemma and the Ninja Yoneda lemma.

Further, the left adjoint `colimitAdj.extendAlongYoneda : (Cᵒᵖ ⥤ Type u) ⥤ ℰ` satisfies
`yoneda ⋙ L ≅ A`, that is, an extension of `A : C ⥤ ℰ` to `(Cᵒᵖ ⥤ Type u) ⥤ ℰ` through
`yoneda : C ⥤ Cᵒᵖ ⥤ Type u`. It is the left Kan extension of `A` along the yoneda embedding,
sometimes known as the Yoneda extension, as proved in `extendAlongYonedaIsoKan`.

`uniqueExtensionAlongYoneda` shows `extendAlongYoneda` is unique amongst cocontinuous functors
with this property, establishing the presheaf category as the free cocompletion of a small category.

We also give a direct pedestrian proof that every presheaf is a colimit of representables. This
version of the proof is valid for any category `C`, even if it is not small.

## Tags
colimit, representable, presheaf, free cocompletion

## References
* [S. MacLane, I. Moerdijk, *Sheaves in Geometry and Logic*][MM92]
* https://ncatlab.org/nlab/show/Yoneda+extension
-/

set_option autoImplicit true


namespace CategoryTheory

open Category Limits

universe v₁ v₂ u₁ u₂

section SmallCategory

variable {C : Type u₁} [SmallCategory C]

variable {ℰ : Type u₂} [Category.{u₁} ℰ]

variable (A : C ⥤ ℰ)

namespace ColimitAdj

/--
The functor taking `(E : ℰ) (c : Cᵒᵖ)` to the homset `(A.obj C ⟶ E)`. It is shown in `L_adjunction`
that this functor has a left adjoint (provided `E` has colimits) given by taking colimits over
categories of elements.
In the case where `ℰ = Cᵒᵖ ⥤ Type u` and `A = yoneda`, this functor is isomorphic to the identity.

Defined as in [MM92], Chapter I, Section 5, Theorem 2.
-/
@[simps!]
def restrictedYoneda : ℰ ⥤ Cᵒᵖ ⥤ Type u₁ :=
  yoneda ⋙ (whiskeringLeft _ _ (Type u₁)).obj (Functor.op A)
#align category_theory.colimit_adj.restricted_yoneda CategoryTheory.ColimitAdj.restrictedYoneda

/--
The functor `restrictedYoneda` is isomorphic to the identity functor when evaluated at the yoneda
embedding.
-/
def restrictedYonedaYoneda : restrictedYoneda (yoneda : C ⥤ Cᵒᵖ ⥤ Type u₁) ≅ 𝟭 _ :=
  NatIso.ofComponents fun P =>
    NatIso.ofComponents (fun X => yonedaSectionsSmall X.unop _) @ fun X Y f =>
      funext fun x => by
        dsimp
        have : x.app X (CategoryStruct.id (Opposite.unop X)) =
            (x.app X (𝟙 (Opposite.unop X))) := rfl
        rw [this]
        rw [← FunctorToTypes.naturality _ _ x f (𝟙 _)]
        simp only [id_comp, Functor.op_obj, Opposite.unop_op, yoneda_obj_map, comp_id]
#align category_theory.colimit_adj.restricted_yoneda_yoneda CategoryTheory.ColimitAdj.restrictedYonedaYoneda

/-- (Implementation). The equivalence of homsets which helps construct the left adjoint to
`colimitAdj.restrictedYoneda`.
It is shown in `restrictYonedaHomEquivNatural` that this is a natural bijection.
-/
def restrictYonedaHomEquiv (P : Cᵒᵖ ⥤ Type u₁) (E : ℰ)
    {c : Cocone ((CategoryOfElements.π P).leftOp ⋙ A)} (t : IsColimit c) :
    (c.pt ⟶ E) ≃ (P ⟶ (restrictedYoneda A).obj E) :=
  ((uliftTrivial _).symm ≪≫ t.homIso' E).toEquiv.trans
    { toFun := fun k =>
        { app := fun c p => k.1 (Opposite.op ⟨_, p⟩)
          naturality := fun c c' f =>
            funext fun p =>
              (k.2
                  (Quiver.Hom.op ⟨f, rfl⟩ :
                    (Opposite.op ⟨c', P.map f p⟩ : P.Elementsᵒᵖ) ⟶ Opposite.op ⟨c, p⟩)).symm }
      invFun := fun τ =>
        { val := fun p => τ.app p.unop.1 p.unop.2
          property := @fun p p' f => by
            simp_rw [← f.unop.2]
            apply (congr_fun (τ.naturality f.unop.1) p'.unop.2).symm }
      left_inv := by
        rintro ⟨k₁, k₂⟩
        ext
        dsimp
        congr 1
      right_inv := by
        rintro ⟨_, _⟩
        rfl }
#align category_theory.colimit_adj.restrict_yoneda_hom_equiv CategoryTheory.ColimitAdj.restrictYonedaHomEquiv

/--
(Implementation). Show that the bijection in `restrictYonedaHomEquiv` is natural (on the right).
-/
theorem restrictYonedaHomEquiv_natural (P : Cᵒᵖ ⥤ Type u₁) (E₁ E₂ : ℰ) (g : E₁ ⟶ E₂) {c : Cocone _}
    (t : IsColimit c) (k : c.pt ⟶ E₁) :
    restrictYonedaHomEquiv A P E₂ t (k ≫ g) =
      restrictYonedaHomEquiv A P E₁ t k ≫ (restrictedYoneda A).map g := by
  ext x X
  apply (assoc _ _ _).symm
#align category_theory.colimit_adj.restrict_yoneda_hom_equiv_natural CategoryTheory.ColimitAdj.restrictYonedaHomEquiv_natural

variable [HasColimits ℰ]

/--
The left adjoint to the functor `restrictedYoneda` (shown in `yonedaAdjunction`). It is also an
extension of `A` along the yoneda embedding (shown in `isExtensionAlongYoneda`), in particular
it is the left Kan extension of `A` through the yoneda embedding.
-/
noncomputable def extendAlongYoneda : (Cᵒᵖ ⥤ Type u₁) ⥤ ℰ :=
  Adjunction.leftAdjointOfEquiv (fun P E => restrictYonedaHomEquiv A P E (colimit.isColimit _))
    fun P E E' g => restrictYonedaHomEquiv_natural A P E E' g _
#align category_theory.colimit_adj.extend_along_yoneda CategoryTheory.ColimitAdj.extendAlongYoneda

@[simp]
theorem extendAlongYoneda_obj (P : Cᵒᵖ ⥤ Type u₁) :
    (extendAlongYoneda A).obj P = colimit ((CategoryOfElements.π P).leftOp ⋙ A) :=
  rfl
#align category_theory.colimit_adj.extend_along_yoneda_obj CategoryTheory.ColimitAdj.extendAlongYoneda_obj

-- porting note: adding this lemma because lean 4 ext no longer applies all ext lemmas when
-- stuck (and hence can see through definitional equalities). The previous lemma shows that
-- `(extendAlongYoneda A).obj P` is definitionally a colimit, and the ext lemma is just
-- a special case of `CategoryTheory.Limits.colimit.hom_ext`.
-- See https://github.com/leanprover-community/mathlib4/issues/5229
@[ext] lemma extendAlongYoneda_obj.hom_ext {P : Cᵒᵖ ⥤ Type u₁}
    {f f' : (extendAlongYoneda A).obj P ⟶ X}
    (w : ∀ j, colimit.ι ((CategoryOfElements.π P).leftOp ⋙ A) j ≫ f =
      colimit.ι ((CategoryOfElements.π P).leftOp ⋙ A) j ≫ f') : f = f' :=
CategoryTheory.Limits.colimit.hom_ext w

theorem extendAlongYoneda_map {X Y : Cᵒᵖ ⥤ Type u₁} (f : X ⟶ Y) :
    (extendAlongYoneda A).map f =
      colimit.pre ((CategoryOfElements.π Y).leftOp ⋙ A) (CategoryOfElements.map f).op := by
  ext J
  erw [colimit.ι_pre ((CategoryOfElements.π Y).leftOp ⋙ A) (CategoryOfElements.map f).op]
  dsimp only [extendAlongYoneda, restrictYonedaHomEquiv, IsColimit.homIso', IsColimit.homIso,
    uliftTrivial]
  -- porting note: in mathlib3 the rest of the proof was `simp, refl`; this is squeezed
  -- and appropriately reordered, presumably because of a non-confluence issue.
  simp only [Adjunction.leftAdjointOfEquiv_map, Iso.symm_mk, Iso.toEquiv_comp, Equiv.coe_trans,
    Equiv.coe_fn_mk, Iso.toEquiv_fun, Equiv.symm_trans_apply, Equiv.coe_fn_symm_mk,
    Iso.toEquiv_symm_fun, id.def, colimit.isColimit_desc, colimit.ι_desc, FunctorToTypes.comp,
    Cocone.extend_ι, Cocone.extensions_app, Functor.map_id, Category.comp_id, colimit.cocone_ι]
  simp only [Functor.comp_obj, Functor.leftOp_obj, CategoryOfElements.π_obj, colimit.cocone_x,
    Functor.comp_map, Functor.leftOp_map, CategoryOfElements.π_map, Opposite.unop_op,
    Adjunction.leftAdjointOfEquiv_obj, Function.comp_apply, Functor.map_id, comp_id,
    colimit.cocone_ι, Functor.op_obj]
  rfl
#align category_theory.colimit_adj.extend_along_yoneda_map CategoryTheory.ColimitAdj.extendAlongYoneda_map

/-- Show `extendAlongYoneda` is left adjoint to `restrictedYoneda`.

The construction of [MM92], Chapter I, Section 5, Theorem 2.
-/
noncomputable def yonedaAdjunction : extendAlongYoneda A ⊣ restrictedYoneda A :=
  Adjunction.adjunctionOfEquivLeft _ _
#align category_theory.colimit_adj.yoneda_adjunction CategoryTheory.ColimitAdj.yonedaAdjunction

/--
The initial object in the category of elements for a representable functor. In `isInitial` it is
shown that this is initial.
-/
def Elements.initial (A : C) : (yoneda.obj A).Elements :=
  ⟨Opposite.op A, 𝟙 _⟩
#align category_theory.colimit_adj.elements.initial CategoryTheory.ColimitAdj.Elements.initial

/-- Show that `Elements.initial A` is initial in the category of elements for the `yoneda` functor.
-/
def isInitial (A : C) : IsInitial (Elements.initial A) where
  desc s := ⟨s.pt.2.op, comp_id _⟩
  uniq s m _ := by
    simp_rw [← m.2]
    dsimp [Elements.initial]
    simp
  fac := by rintro s ⟨⟨⟩⟩
#align category_theory.colimit_adj.is_initial CategoryTheory.ColimitAdj.isInitial

/--
`extendAlongYoneda A` is an extension of `A` to the presheaf category along the yoneda embedding.
`uniqueExtensionAlongYoneda` shows it is unique among functors preserving colimits with this
property (up to isomorphism).

The first part of [MM92], Chapter I, Section 5, Corollary 4.
See Property 1 of <https://ncatlab.org/nlab/show/Yoneda+extension#properties>.
-/
noncomputable def isExtensionAlongYoneda :
    (yoneda : C ⥤ Cᵒᵖ ⥤ Type u₁) ⋙ extendAlongYoneda A ≅ A :=
  NatIso.ofComponents
    (fun X =>
      (colimit.isColimit _).coconePointUniqueUpToIso
        (colimitOfDiagramTerminal (terminalOpOfInitial (isInitial _)) _))
    (by
      intro X Y f
      -- porting note: this is slightly different to the `change` in mathlib3 which
      -- didn't work
      change (colimit.desc _ _ ≫ _) = colimit.desc _ _ ≫ _
      ext
      rw [colimit.ι_desc_assoc, colimit.ι_desc_assoc]
      change (colimit.ι _ _ ≫ 𝟙 _) ≫ colimit.desc _ _ = _
      rw [comp_id, colimit.ι_desc]
      dsimp
      rw [← A.map_comp]
      congr 1)
#align category_theory.colimit_adj.is_extension_along_yoneda CategoryTheory.ColimitAdj.isExtensionAlongYoneda

/-- See Property 2 of https://ncatlab.org/nlab/show/Yoneda+extension#properties. -/
noncomputable instance : PreservesColimits (extendAlongYoneda A) :=
  (yonedaAdjunction A).leftAdjointPreservesColimits

/-- Show that the images of `X` after `extendAlongYoneda` and `Lan yoneda` are indeed isomorphic.
This follows from `CategoryTheory.CategoryOfElements.costructuredArrowYonedaEquivalence`.
-/
@[simps]
noncomputable def extendAlongYonedaIsoKanApp (X) :
    (extendAlongYoneda A).obj X ≅ ((lan yoneda : (_ ⥤ ℰ) ⥤ _).obj A).obj X :=
  let eq := CategoryOfElements.costructuredArrowYonedaEquivalence X
  { hom := colimit.pre (Lan.diagram (yoneda : C ⥤ _ ⥤ Type u₁) A X) eq.functor
    inv := colimit.pre ((CategoryOfElements.π X).leftOp ⋙ A) eq.inverse
    hom_inv_id := by
      erw [colimit.pre_pre ((CategoryOfElements.π X).leftOp ⋙ A) eq.inverse]
      trans colimit.pre ((CategoryOfElements.π X).leftOp ⋙ A) (𝟭 _)
      congr
      · exact congr_arg Functor.op (CategoryOfElements.from_toCostructuredArrow_eq X)
      · ext
        simp only [colimit.ι_pre]
        erw [Category.comp_id]
        congr
    inv_hom_id := by
      erw [colimit.pre_pre (Lan.diagram (yoneda : C ⥤ _ ⥤ Type u₁) A X) eq.functor]
      trans colimit.pre (Lan.diagram (yoneda : C ⥤ _ ⥤ Type u₁) A X) (𝟭 _)
      congr
      · exact CategoryOfElements.to_fromCostructuredArrow_eq X
      · ext
        simp only [colimit.ι_pre]
        erw [Category.comp_id]
        congr }
set_option linter.uppercaseLean3 false in
#align category_theory.colimit_adj.extend_along_yoneda_iso_Kan_app CategoryTheory.ColimitAdj.extendAlongYonedaIsoKanApp

/-- Verify that `extendAlongYoneda` is indeed the left Kan extension along the yoneda embedding.
-/
@[simps!]
noncomputable def extendAlongYonedaIsoKan :
    extendAlongYoneda A ≅ (lan yoneda : (_ ⥤ ℰ) ⥤ _).obj A :=
  NatIso.ofComponents (extendAlongYonedaIsoKanApp A) (by
    intro X Y f; simp
    rw [extendAlongYoneda_map]
    erw [colimit.pre_pre (Lan.diagram (yoneda : C ⥤ _ ⥤ Type u₁) A Y) (CostructuredArrow.map f)]
    erw [colimit.pre_pre (Lan.diagram (yoneda : C ⥤ _ ⥤ Type u₁) A Y)
        (CategoryOfElements.costructuredArrowYonedaEquivalence Y).functor]
    congr 1
    apply CategoryOfElements.costructuredArrow_yoneda_equivalence_naturality)
set_option linter.uppercaseLean3 false in
#align category_theory.colimit_adj.extend_along_yoneda_iso_Kan CategoryTheory.ColimitAdj.extendAlongYonedaIsoKan

/-- extending `F ⋙ yoneda` along the yoneda embedding is isomorphic to `Lan F.op`. -/
noncomputable def extendOfCompYonedaIsoLan {D : Type u₁} [SmallCategory D] (F : C ⥤ D) :
    extendAlongYoneda (F ⋙ yoneda) ≅ lan F.op :=
  Adjunction.natIsoOfRightAdjointNatIso (yonedaAdjunction (F ⋙ yoneda))
    (Lan.adjunction (Type u₁) F.op)
    (isoWhiskerRight curriedYonedaLemma' ((whiskeringLeft Cᵒᵖ Dᵒᵖ (Type u₁)).obj F.op : _))
set_option linter.uppercaseLean3 false in
#align category_theory.colimit_adj.extend_of_comp_yoneda_iso_Lan CategoryTheory.ColimitAdj.extendOfCompYonedaIsoLan

-- porting note: attaching `[simps!]` directly to the declaration causes a timeout.
attribute [simps!] extendOfCompYonedaIsoLan

end ColimitAdj

open ColimitAdj

/-- `F ⋙ yoneda` is naturally isomorphic to `yoneda ⋙ Lan F.op`. -/
@[simps!]
noncomputable def compYonedaIsoYonedaCompLan {D : Type u₁} [SmallCategory D] (F : C ⥤ D) :
    F ⋙ yoneda ≅ yoneda ⋙ lan F.op :=
  (isExtensionAlongYoneda (F ⋙ yoneda)).symm ≪≫ isoWhiskerLeft yoneda (extendOfCompYonedaIsoLan F)
set_option linter.uppercaseLean3 false in
#align category_theory.comp_yoneda_iso_yoneda_comp_Lan CategoryTheory.compYonedaIsoYonedaCompLan

/-- Since `extendAlongYoneda A` is adjoint to `restrictedYoneda A`, if we use `A = yoneda`
then `restrictedYoneda A` is isomorphic to the identity, and so `extendAlongYoneda A` is as well.
-/
noncomputable def extendAlongYonedaYoneda : extendAlongYoneda (yoneda : C ⥤ _) ≅ 𝟭 _ :=
  Adjunction.natIsoOfRightAdjointNatIso (yonedaAdjunction _) Adjunction.id restrictedYonedaYoneda
#align category_theory.extend_along_yoneda_yoneda CategoryTheory.extendAlongYonedaYoneda

-- Maybe this should be reducible or an abbreviation?
/-- A functor to the presheaf category in which everything in the image is representable (witnessed
by the fact that it factors through the yoneda embedding).
`coconeOfRepresentable` gives a cocone for this functor which is a colimit and has point `P`.
-/
def functorToRepresentables (P : Cᵒᵖ ⥤ Type u₁) : P.Elementsᵒᵖ ⥤ Cᵒᵖ ⥤ Type u₁ :=
  (CategoryOfElements.π P).leftOp ⋙ yoneda
#align category_theory.functor_to_representables CategoryTheory.functorToRepresentables

/-- This is a cocone with point `P` for the functor `functorToRepresentables P`. It is shown in
`colimitOfRepresentable P` that this cocone is a colimit: that is, we have exhibited an arbitrary
presheaf `P` as a colimit of representables.

The construction of [MM92], Chapter I, Section 5, Corollary 3.
-/
noncomputable def coconeOfRepresentable (P : Cᵒᵖ ⥤ Type u₁) : Cocone (functorToRepresentables P) :=
  Cocone.extend (colimit.cocone _) (extendAlongYonedaYoneda.hom.app P)
#align category_theory.cocone_of_representable CategoryTheory.coconeOfRepresentable

@[simp]
theorem coconeOfRepresentable_pt (P : Cᵒᵖ ⥤ Type u₁) : (coconeOfRepresentable P).pt = P :=
  rfl
set_option linter.uppercaseLean3 false in
#align category_theory.cocone_of_representable_X CategoryTheory.coconeOfRepresentable_pt

-- Marking this as a simp lemma seems to make things more awkward.
/-- An explicit formula for the legs of the cocone `coconeOfRepresentable`. -/
theorem coconeOfRepresentable_ι_app (P : Cᵒᵖ ⥤ Type u₁) (j : P.Elementsᵒᵖ) :
    (coconeOfRepresentable P).ι.app j = (yonedaSectionsSmall _ _).inv j.unop.2 :=
  colimit.ι_desc _ _
#align category_theory.cocone_of_representable_ι_app CategoryTheory.coconeOfRepresentable_ι_app

/-- The legs of the cocone `coconeOfRepresentable` are natural in the choice of presheaf. -/
theorem coconeOfRepresentable_naturality {P₁ P₂ : Cᵒᵖ ⥤ Type u₁} (α : P₁ ⟶ P₂) (j : P₁.Elementsᵒᵖ) :
    (coconeOfRepresentable P₁).ι.app j ≫ α =
      (coconeOfRepresentable P₂).ι.app ((CategoryOfElements.map α).op.obj j) := by
  ext T f
  simpa [coconeOfRepresentable_ι_app] using FunctorToTypes.naturality _ _ α f.op _
#align category_theory.cocone_of_representable_naturality CategoryTheory.coconeOfRepresentable_naturality

/-- The cocone with point `P` given by `coconeOfRepresentable` is a colimit:
that is, we have exhibited an arbitrary presheaf `P` as a colimit of representables.

The result of [MM92], Chapter I, Section 5, Corollary 3.
-/
noncomputable def colimitOfRepresentable (P : Cᵒᵖ ⥤ Type u₁) :
    IsColimit (coconeOfRepresentable P) := by
  -- porting note:
  -- the `suffices` was not necessary in mathlib3; the function being `apply`ed has an
  -- `IsIso` input in square brackets; lean 3 was happy to give the user the input as a goal but
  -- lean 4 complains that typeclass inference can't find it.
  suffices IsIso (IsColimit.desc (colimit.isColimit (functorToRepresentables P))
    (coconeOfRepresentable P)) by
    apply IsColimit.ofPointIso (colimit.isColimit (functorToRepresentables P))
  change IsIso (colimit.desc _ (Cocone.extend _ _))
  rw [colimit.desc_extend, colimit.desc_cocone]
  infer_instance
#align category_theory.colimit_of_representable CategoryTheory.colimitOfRepresentable

/-- Given two functors L₁ and L₂ which preserve colimits, if they agree when restricted to the
representable presheaves then they agree everywhere.
-/
noncomputable def natIsoOfNatIsoOnRepresentables (L₁ L₂ : (Cᵒᵖ ⥤ Type u₁) ⥤ ℰ)
    [PreservesColimits L₁] [PreservesColimits L₂] (h : yoneda ⋙ L₁ ≅ yoneda ⋙ L₂) : L₁ ≅ L₂ := by
  apply NatIso.ofComponents _ _
  · intro P
    refine'
      (isColimitOfPreserves L₁ (colimitOfRepresentable P)).coconePointsIsoOfNatIso
        (isColimitOfPreserves L₂ (colimitOfRepresentable P)) _
    apply Functor.associator _ _ _ ≪≫ _
    exact isoWhiskerLeft (CategoryOfElements.π P).leftOp h
  · intro P₁ P₂ f
    apply (isColimitOfPreserves L₁ (colimitOfRepresentable P₁)).hom_ext
    intro j
    dsimp only [id.def, IsColimit.comp_coconePointsIsoOfNatIso_hom, isoWhiskerLeft_hom]
    have :
      (L₁.mapCocone (coconeOfRepresentable P₁)).ι.app j ≫ L₁.map f =
        (L₁.mapCocone (coconeOfRepresentable P₂)).ι.app
          ((CategoryOfElements.map f).op.obj j) := by
      dsimp
      rw [← L₁.map_comp, coconeOfRepresentable_naturality]
      rfl
    erw [reassoc_of% this, IsColimit.ι_map_assoc, IsColimit.ι_map]
    dsimp
    rw [← L₂.map_comp, coconeOfRepresentable_naturality]
    rfl
#align category_theory.nat_iso_of_nat_iso_on_representables CategoryTheory.natIsoOfNatIsoOnRepresentables

variable [HasColimits ℰ]

/-- Show that `extendAlongYoneda` is the unique colimit-preserving functor which extends `A` to
the presheaf category.

The second part of [MM92], Chapter I, Section 5, Corollary 4.
See Property 3 of https://ncatlab.org/nlab/show/Yoneda+extension#properties.
-/
noncomputable def uniqueExtensionAlongYoneda (L : (Cᵒᵖ ⥤ Type u₁) ⥤ ℰ) (hL : yoneda ⋙ L ≅ A)
    [PreservesColimits L] : L ≅ extendAlongYoneda A :=
  natIsoOfNatIsoOnRepresentables _ _ (hL ≪≫ (isExtensionAlongYoneda _).symm)
#align category_theory.unique_extension_along_yoneda CategoryTheory.uniqueExtensionAlongYoneda

/-- If `L` preserves colimits and `ℰ` has them, then it is a left adjoint. This is a special case of
`isLeftAdjointOfPreservesColimits` used to prove that.
-/
noncomputable def isLeftAdjointOfPreservesColimitsAux (L : (Cᵒᵖ ⥤ Type u₁) ⥤ ℰ)
    [PreservesColimits L] : IsLeftAdjoint L where
  right := restrictedYoneda (yoneda ⋙ L)
  adj := (yonedaAdjunction _).ofNatIsoLeft (uniqueExtensionAlongYoneda _ L (Iso.refl _)).symm
#align category_theory.is_left_adjoint_of_preserves_colimits_aux CategoryTheory.isLeftAdjointOfPreservesColimitsAux

/-- If `L` preserves colimits and `ℰ` has them, then it is a left adjoint. Note this is a (partial)
converse to `leftAdjointPreservesColimits`.
-/
noncomputable def isLeftAdjointOfPreservesColimits (L : (C ⥤ Type u₁) ⥤ ℰ) [PreservesColimits L] :
    IsLeftAdjoint L :=
  let e : _ ⥤ Type u₁ ≌ _ ⥤ Type u₁ := (opOpEquivalence C).congrLeft
  let _ := isLeftAdjointOfPreservesColimitsAux (e.functor ⋙ L : _)
  Adjunction.leftAdjointOfNatIso (e.invFunIdAssoc _)
#align category_theory.is_left_adjoint_of_preserves_colimits CategoryTheory.isLeftAdjointOfPreservesColimits

end SmallCategory

section ArbitraryUniverses

variable {C : Type u₁} [Category.{v₁} C] (P : Cᵒᵖ ⥤ Type v₁)

/-- For a presheaf `P`, consider the forgetful functor from the category of representable
    presheaves over `P` to the category of presheaves. There is a tautological cocone over this
    functor whose leg for a natural transformation `V ⟶ P` with `V` representable is just that
    natural transformation. -/
@[simps]
def tautologicalCocone : Cocone (CostructuredArrow.proj yoneda P ⋙ yoneda) where
  pt := P
  ι := { app := fun X => X.hom }

/-- The tautological cocone with point `P` is a colimit cocone, exhibiting `P` as a colimit of
    representables. -/
def isColimitTautologicalCocone : IsColimit (tautologicalCocone P) where
  desc := fun s => by
    refine' ⟨fun X t => yonedaEquiv (s.ι.app (CostructuredArrow.mk (yonedaEquiv.symm t))), _⟩
    intros X Y f
    ext t
    dsimp
    -- This used to be `rw`, but we need `erw` after leanprover/lean4#2644
    erw [yonedaEquiv_naturality', yonedaEquiv_symm_map]
    simpa using (s.ι.naturality
      (CostructuredArrow.homMk' (CostructuredArrow.mk (yonedaEquiv.symm t)) f.unop)).symm
  fac := by
    intro s t
    dsimp
    apply yonedaEquiv.injective
    rw [yonedaEquiv_comp]
    dsimp only
    -- This used to be `rw`, but we need `erw` after leanprover/lean4#2644
    erw [Equiv.symm_apply_apply]
    rfl
  uniq := by
    intro s j h
    ext V x
    obtain ⟨t, rfl⟩ := yonedaEquiv.surjective x
    dsimp
    -- This used to be `rw`, but we need `erw` after leanprover/lean4#2644
    erw [Equiv.symm_apply_apply, ← yonedaEquiv_comp']
    exact congr_arg _ (h (CostructuredArrow.mk t))

lemma a : 0 = 0 := rfl

variable {I : Type v₁} [SmallCategory I] (α : I ⥤ C)

@[simps]
def blub₂ (A : Cᵒᵖ ⥤ Type v₁) (η : Over A) : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v₁ where
  obj := fun s => { u : η.left.obj (Opposite.op s.unop.left) //
    η.hom.app (Opposite.op s.unop.left) u = yonedaEquiv s.unop.hom }
  map := fun {t s} f u => by
    refine' ⟨η.left.map f.unop.left.op u.1, _⟩
    have := congr_fun (η.hom.naturality f.unop.left.op) u.1
    dsimp at this
    rw [this, u.2, ← CostructuredArrow.w f.unop, ← yonedaEquiv_naturality]
    rfl

attribute [-simp] yonedaEquiv_apply

@[simps]
def terribleFunctor (A : Cᵒᵖ ⥤ Type v₁) : Over A ⥤ (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v₁ where
  obj := blub₂ A
  map := fun {η μ} ε =>
    { app := fun s => by
        dsimp
        intro u
        refine' ⟨ε.left.app (Opposite.op s.unop.left) u, _⟩
        have := ε.w
        simp [-Over.w] at this
        simp only [← u.2, ← this]
        simp [-Over.w]
      naturality := by
        intros t s f
        ext u
        simp
        ext
        exact congr_fun (ε.left.naturality _) _ }

lemma b : 0 = 0 := rfl

instance abc {X : C} {F : Cᵒᵖ ⥤ Type v₁} : Small.{v₁} (yoneda.obj X ⟶ F) :=
  Small.mk' yonedaEquiv

instance u {X : C} {A : Cᵒᵖ ⥤ Type v₁} : HasCoproductsOfShape (yoneda.obj X ⟶ A) (Type v₁) :=
  hasCoproductsOfShape_of_small _ _

/-- Why is this needed?? -/
instance {X : Cᵒᵖ} {A : Cᵒᵖ ⥤ Type v₁} (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v₁) :
    HasCoproduct (fun (s : yoneda.obj X.unop ⟶ A) => F.obj (Opposite.op (CostructuredArrow.mk s))) :=
  u.has_colimit _

@[simps (config := { fullyApplied := false }) obj map]
noncomputable def bla₂ (A : Cᵒᵖ ⥤ Type v₁) (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v₁) :
    Cᵒᵖ ⥤ Type v₁ where
  obj := fun X => ∐ fun (s : yoneda.obj X.unop ⟶ A) => F.obj (Opposite.op (CostructuredArrow.mk s))
  map := fun {X Y} f => Sigma.map' (fun s => yoneda.map f.unop ≫ s)
    (fun s => F.map (Quiver.Hom.op (CostructuredArrow.homMk' (CostructuredArrow.mk s) _)))
  map_id := fun X => by
    dsimp only [unop_id]
    rw [← Sigma.map'_id_id]
    refine' Sigma.map'_eq _ _
    · ext
      simp only [Functor.map_id, id_comp, id_eq]
    · intro s
      simp only [id_eq]
      rw [CostructuredArrow.homMk'_mk_id]
      rw [eqToHom_op, eqToHom_map]
      simp only [id_eq, eqToHom_trans, eqToHom_refl]
  map_comp := fun {X Y Z} f g => by
    dsimp only [unop_comp]
    rw [Sigma.map'_comp_map']
    refine' Sigma.map'_eq _ _
    · ext
      simp only [Functor.map_comp, assoc, FunctorToTypes.comp, yoneda_map_app, Function.comp_apply]
    · intro s
      rw [← F.map_comp, ← op_comp]
      rw [CostructuredArrow.homMk'_mk_comp]
      rw [op_comp, F.map_comp, eqToHom_op, eqToHom_map, Category.assoc, eqToHom_trans, eqToHom_refl, Category.comp_id]

attribute [local simp] Sigma.map'_comp_map Sigma.map_comp_map'

@[simps (config := { fullyApplied := false })]
noncomputable def bla₂' (A : Cᵒᵖ ⥤ Type v₁) : ((CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v₁) ⥤ Cᵒᵖ ⥤ Type v₁ where
  obj := bla₂ A
  map := fun {F G} η => { app := fun X => Sigma.map' id (fun x => η.app _) }
  map_id := by
    intro F
    ext1
    ext1 x
    dsimp
    apply Sigma.hom_ext
    intro s
    simp only [ι_colimMap, Discrete.functor_obj, Discrete.natTrans_app, id_comp, comp_id]
  map_comp := by
    intro F G H η μ
    ext1
    ext1 X
    dsimp
    apply Sigma.hom_ext
    intro s
    simp only [ι_colimMap, Discrete.functor_obj, Discrete.natTrans_app, assoc, ι_colimMap_assoc]

@[simps (config := { fullyApplied := false })]
noncomputable def bla₂'' (A : Cᵒᵖ ⥤ Type v₁) (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v₁) :
    (bla₂' A).obj F ⟶ A where
  app := fun X => Sigma.desc (fun s _ => yonedaEquiv s)
  naturality := by
    intros X Y f
    apply Sigma.hom_ext
    intro s
    simp
    ext x
    exact (yonedaEquiv_naturality' _ _).symm

@[simp]
noncomputable def terribleReverse (A : Cᵒᵖ ⥤ Type v₁) : ((CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v₁) ⥤ Over A :=
  (bla₂' A).toOver A (bla₂'' A) (by
    intros F G η
    ext1
    ext1 X
    dsimp
    apply Sigma.hom_ext
    intro s
    simp
    ext1
    simp)

def terribleTriangle' (A : Cᵒᵖ ⥤ Type v₁) :
    CostructuredArrow.toOver yoneda A ⋙ terribleFunctor A ≅ yoneda :=
  NatIso.ofComponents (fun s => by
    refine' NatIso.ofComponents (fun t => _) _
    · dsimp
      refine' ⟨fun f => _, fun f => _, _, _⟩
      · refine' CostructuredArrow.homMk f.1 _
        apply yonedaEquiv.injective
        rw [yonedaEquiv_comp, yonedaEquiv_yoneda_map, f.2]
        rfl
      · refine' ⟨f.left, _⟩
        have := f.w
        simp [-CommaMorphism.w] at this
        rw [← this, yonedaEquiv_comp, yonedaEquiv_yoneda_map]
      · aesop_cat
      · aesop_cat
    · aesop_cat) (by aesop_cat)

theorem c : 0 = 0 := rfl

instance {X : Cᵒᵖ} {A : Cᵒᵖ ⥤ Type v₁} (η : Over A) :
    HasCoproduct (fun (s : yoneda.obj X.unop ⟶ A) => { u : η.left.obj X // NatTrans.app η.hom X u = yonedaEquiv s }) :=
  u.has_colimit _

@[simps!]
noncomputable def unit_pt (A : Cᵒᵖ ⥤ Type v₁) (η : Over A) :
    (terribleFunctor A ⋙ terribleReverse A).obj η ≅ η := by
  refine' Over.isoMk (NatIso.ofComponents (fun X => _) _) _
  · dsimp
    refine' ⟨Sigma.desc fun s u => u.1, fun u => _, _, _⟩
    · refine' Sigma.ι (fun (s : yoneda.obj X.unop ⟶ A) => { u : η.left.obj X // NatTrans.app η.hom X u = yonedaEquiv s })
        (yonedaEquiv.symm (η.hom.app X u)) ⟨u, _⟩
      erw [Equiv.apply_symm_apply]
    · apply Sigma.hom_ext
      intro s
      simp
      ext u
      simp
      rcases u with ⟨u, hu⟩
      have : s = yonedaEquiv.symm (NatTrans.app η.hom X u)
      · erw [hu, Equiv.symm_apply_apply]
      subst this
      simp only [Functor.const_obj_obj, Opposite.op_unop, Functor.id_obj]
    · ext x
      dsimp
      erw [← types_comp_apply (Sigma.ι _ _) (Sigma.desc _)]
      rw [colimit.ι_desc]
      simp only [Cofan.mk_pt, Cofan.mk_ι_app]
  · intros X Y f
    simp
    apply Sigma.hom_ext
    intro s
    ext u
    rw [Sigma.ι_comp_map'_assoc, colimit.ι_desc_assoc]
    simp only [colimit.ι_desc, Cofan.mk_pt, Cofan.mk_ι_app, types_comp_apply, blub₂_map_coe, Opposite.unop_op,
      CostructuredArrow.mk_left, Opposite.op_unop, Quiver.Hom.unop_op, CostructuredArrow.homMk'_left,
      Quiver.Hom.op_unop, Functor.const_obj_obj, Functor.id_obj, CostructuredArrow.mk_right,
      CostructuredArrow.mk_hom_eq_self, Discrete.functor_obj]
  · apply NatTrans.ext
    apply funext
    intro X
    apply Sigma.hom_ext
    intro s
    dsimp
    ext u
    erw [colimit.ι_desc, colimit.ι_desc_assoc]
    simp [u.2]

noncomputable def unit (A : Cᵒᵖ ⥤ Type v₁) : (terribleFunctor A ⋙ terribleReverse A) ≅ 𝟭 (Over A) :=
  NatIso.ofComponents (unit_pt A) (by
    intros η μ ε
    apply CostructuredArrow.hom_ext
    apply NatTrans.ext
    apply funext
    intro X
    apply Sigma.hom_ext
    intro s
    ext u
    dsimp
    erw [← types_comp_apply (Sigma.ι _ _) (Sigma.desc _), colimit.ι_desc,
      ← types_comp_apply (Sigma.ι _ _) (Limits.Sigma.map _)]
    rw [← Sigma.map'_id, Sigma.ι_comp_map']
    simp
    erw [← types_comp_apply (Sigma.ι _ _) (Sigma.desc _), colimit.ι_desc]
    simp)

instance {A : Cᵒᵖ ⥤ Type v₁} (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v₁) (X : (CostructuredArrow yoneda A)ᵒᵖ) :
    HasCoproduct (fun (s : yoneda.obj X.unop.left ⟶ A) => F.obj (Opposite.op (CostructuredArrow.mk s))) :=
  u.has_colimit _

open Classical

lemma Iso.op_trans {X Y Z : C} (i : X ≅ Y) (j : Y ≅ Z) : Iso.op (i ≪≫ j) = Iso.op j ≪≫ Iso.op i :=
  rfl

lemma eqToIso_op {X Y : C} (h : X = Y) : (eqToIso h).op = eqToIso (by rw [h]) := by
  aesop_cat

set_option maxHeartbeats 2000000

@[simps!]
noncomputable def counit_pt (A : Cᵒᵖ ⥤ Type v₁) (F : (CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v₁) :
    F ≅ (terribleReverse A ⋙ terribleFunctor A).obj F := by
  refine' (NatIso.ofComponents (fun X => _) _).symm
  · refine' ⟨fun u => _, fun u => _, _, _⟩
    swap
    · refine' ⟨_, _⟩
      · refine' (_ ≫ Sigma.ι (fun (s : yoneda.obj X.unop.left ⟶ A) => F.obj (Opposite.op (CostructuredArrow.mk s))) X.unop.hom) u
        refine' (F.mapIso _).hom
        refine' Iso.op _
        exact (CostructuredArrow.eta X.unop).symm
      · --sorry -- DONE!
        dsimp [Functor.toOver]
        erw [← types_comp_apply (Sigma.ι _ _) (Sigma.desc _), colimit.ι_desc]
        dsimp only [Cofan.mk_pt, Cofan.mk_ι_app]
    · refine' (F.mapIso (Iso.op _)).hom (Types.Sigma.rep u.1)
      · refine' CostructuredArrow.eta _ ≪≫ CostructuredArrow.mkCongr _
        --sorry -- DONE!
        dsimp [Functor.toOver] at u
        rcases u with ⟨u, hu⟩
        obtain h := Types.Sigma.ι_comp_rep u
        rw [← h] at hu
        erw [← types_comp_apply (Sigma.ι _ _) (Sigma.desc _), colimit.ι_desc] at hu
        dsimp at hu
        exact yonedaEquiv.injective hu.symm
    swap
    · --sorry -- DONE!
      ext u
      dsimp [-Functor.mapIso_hom]
      rw [← Iso.toEquiv_fun, ← Equiv.eq_symm_apply]
      simp only [Types.Sigma.rep_ι]
      rw [← types_comp_apply _ (eqToHom _)]
      refine' congr_fun _ _
      change (F.mapIso _).hom ≫ eqToHom _ = (F.mapIso _).symm.hom
      rw [← Iso.eq_inv_comp]
      simp only [CostructuredArrow.mkCongr_eq_eqToIso, CostructuredArrow.eta_eq_eqToIso]
      simp only [eqToIso_op, eqToIso_map, Functor.mapIso_inv, Iso.symm_inv, Iso.op_inv, eqToIso.hom,
        eqToHom_op, Iso.symm_hom, Functor.mapIso_hom, eqToHom_map, Iso.trans_inv, eqToIso.inv, op_comp, F.map_comp, eqToHom_trans]
      -- rw [F.mapIso_inv, ← F.mapIso_symm, F.mapIso_hom, F.mapIso_hom, ← F.map_comp, Iso.op_inv,
      --   Iso.symm_hom, Iso.op_inv, ← op_comp, ← Iso.trans_inv, Iso.symm_self_id_assoc, CostructuredArrow.mkCongr_eq_eqToIso,
      --   ← Iso.op_inv, eqToIso_op, eqToIso.inv, eqToHom_map]
    · --sorry -- DONE!
      ext1 u
      dsimp [Functor.toOver] at u
      rcases u with ⟨u, hu⟩
      simp only [terribleReverse, Functor.comp_obj, terribleFunctor_obj, blub₂_obj, Functor.toOver_obj_left, bla₂'_obj,
        bla₂_obj, Opposite.unop_op, Functor.const_obj_obj, Functor.id_obj, Opposite.op_unop, types_comp_apply,
        types_id_apply, Subtype.mk.injEq]
      obtain h := Types.Sigma.ι_comp_rep u
      rw [← h] at hu
      erw [← types_comp_apply (Sigma.ι _ _) (Sigma.desc _), colimit.ι_desc] at hu
      dsimp at hu
      simp only [← h]
      rw [Types.Sigma.ι_eq_iff]
      have hh : F.obj (Opposite.op (CostructuredArrow.mk X.unop.hom)) =
        F.obj (Opposite.op (CostructuredArrow.mk (Types.Sigma.comp u))) := by rw [yonedaEquiv.injective hu]
      refine' ⟨yonedaEquiv.injective hu.symm, _⟩
      have hi : eqToHom hh = (F.mapIso (Iso.op (eqToIso (by rw [yonedaEquiv.injective hu])))).hom := by
        simp [eqToIso_op, eqToHom_map]
      rw [hi]
      rw [← types_comp_apply (F.mapIso _).hom (F.mapIso _).hom]
      rw [← Iso.trans_hom, ← F.mapIso_trans]
      rw [← types_comp_apply (F.mapIso _).hom (F.mapIso _).hom]
      rw [← Iso.trans_hom, ← F.mapIso_trans]
      simp only [← Iso.op_trans]
      simp only [Iso.trans_assoc]
      rw [Iso.symm_self_id_assoc]
      rw [CostructuredArrow.mkCongr_eq_eqToIso, eqToIso_trans, eqToIso_op, eqToIso_refl, F.mapIso_refl, Iso.refl_hom]
      simp only [types_id_apply]
  ·
    intros x s f
    dsimp [Functor.toOver]
    ext u
    rcases u with ⟨u, hu⟩
    obtain h := Types.Sigma.ι_comp_rep u
    rw [← h] at hu
    erw [← types_comp_apply (Sigma.ι _ _) (Sigma.desc _), colimit.ι_desc] at hu
    dsimp at hu
    dsimp [-Functor.mapIso_hom]
    rw [← types_comp_apply (F.map _) (F.map _), ← F.map_comp]
    simp only [Types.Sigma.rep_map']
    rw [← eqToHom_map]
    swap
    · congr
      rw [Types.Sigma.comp_map']
    ·
      rw [← types_comp_apply (F.map _) (F.map _)]
      rw [← F.map_comp]
      rw [← types_comp_apply (F.map _) (F.map _)]
      rw [← F.map_comp]
      refine' congr_fun _ (Types.Sigma.rep u)
      refine' congr_arg F.map _
      apply Quiver.Hom.unop_inj
      ext
      simp [CostructuredArrow.eqToHom_left]

noncomputable def counit (A : Cᵒᵖ ⥤ Type v₁) : 𝟭 ((CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v₁) ≅ (terribleReverse A ⋙ terribleFunctor A) :=
  Iso.symm $ NatIso.ofComponents (fun F => (counit_pt A F).symm) (by
    intros F G η
    dsimp only [terribleReverse, Functor.comp_obj, terribleFunctor_obj, Functor.id_obj, Functor.comp_map, Iso.symm_hom,
      Functor.id_map]
    ext s u
    dsimp only [Functor.toOver, Functor.toCostructuredArrow_obj, bla₂'_obj, blub₂_obj, CostructuredArrow.mk_left,
      bla₂_obj, Opposite.unop_op, CostructuredArrow.mk_right, Functor.const_obj_obj, Functor.id_obj,
      CostructuredArrow.mk_hom_eq_self, bla₂''_app, Opposite.op_unop] at u
    simp only [FunctorToTypes.comp, terribleFunctor_map_app, blub₂_obj, Functor.toOver_obj_left, bla₂'_obj, bla₂_obj,
      Opposite.unop_op, Functor.const_obj_obj, Functor.id_obj, Functor.toOver_map_left, bla₂'_map_app, Sigma.map'_id,
      id_eq, counit_pt_inv_app, Eq.ndrec]
    simp only [← Sigma.map'_id]
    rw [Types.Sigma.rep_map']
    rw [← types_comp_apply (F.map _) (F.map _), ← F.map_comp, FunctorToTypes.naturality]
    conv_rhs => simp only [← Iso.op_hom]
    rw [← Iso.trans_hom, ← G.mapIso_hom]
    rw [← types_comp_apply (G.map _) (G.map _), ← G.map_comp, ← types_comp_apply (eqToHom _) (G.map _)]
    refine' congr_fun _ (η.app _ _)
    simp only [CostructuredArrow.eta_eq_eqToIso, CostructuredArrow.mkCongr_eq_eqToIso, eqToIso.hom, eqToHom_map, eqToIso_map, eqToIso_op,
      Functor.mapIso_trans, eqToHom_op, Functor.map_comp, eqToHom_trans, Iso.trans_hom])

noncomputable def terribleEquiv (A : Cᵒᵖ ⥤ Type v₁) : Over A ≌ ((CostructuredArrow yoneda A)ᵒᵖ ⥤ Type v₁) :=
  Equivalence.mk (terribleFunctor A) (terribleReverse A) (unit A).symm (counit A).symm

def terribleTriangle (A : Cᵒᵖ ⥤ Type v₁) :
    CostructuredArrow.toOver yoneda A ⋙ (terribleEquiv A).functor ≅ yoneda :=
  terribleTriangle' A

open Functor

theorem final_toCostructuredArrow_comp_pre {c : Cocone (α ⋙ yoneda)} (hc : IsColimit c) :
    Final (c.toCostructuredArrow ⋙ CostructuredArrow.pre α yoneda c.pt) := by
  refine' cofinal_of_colimit_comp_coyoneda_iso_pUnit _ (fun d => _)
  refine' Types.isTerminalEquivIsoPUnit _ _
  suffices IsTerminal (colimit (c.toCostructuredArrow ⋙ CostructuredArrow.pre α _ _ ⋙ yoneda)) by
    let b := IsTerminal.isTerminalObj ((evaluation _ _).obj (Opposite.op d)) _ this
    apply IsTerminal.ofIso b
    let e := preservesColimitIso
      ((evaluation (CostructuredArrow yoneda c.pt)ᵒᵖ (Type v₁)).obj (Opposite.op d))
      (Cocone.toCostructuredArrow c ⋙ CostructuredArrow.pre α yoneda c.pt ⋙ yoneda)
    exact e
  refine' IsTerminal.isTerminalOfObj (terribleEquiv c.pt).inverse
    (colimit (c.toCostructuredArrow ⋙ CostructuredArrow.pre α _ _  ⋙ yoneda)) _
  apply IsTerminal.ofIso (Over.mkIdTerminal)
  let i := preservesColimitIso ((terribleEquiv c.pt).inverse) (Cocone.toCostructuredArrow c ⋙ CostructuredArrow.pre α yoneda c.pt ⋙ yoneda)
  refine' _ ≪≫ i.symm
  let j := terribleTriangle c.pt

  -- TODO: Extract this out
  let k : CostructuredArrow.toOver yoneda c.pt ≅ yoneda ⋙ (terribleEquiv c.pt).inverse := by
    calc
      CostructuredArrow.toOver yoneda c.pt ≅ CostructuredArrow.toOver yoneda c.pt ⋙ (terribleEquiv c.pt).functor ⋙ (terribleEquiv c.pt).inverse
        := isoWhiskerLeft (CostructuredArrow.toOver _ _) ((terribleEquiv c.pt).unitIso)
      _ ≅ yoneda ⋙ (terribleEquiv c.pt).inverse := isoWhiskerRight j (terribleEquiv c.pt).inverse

  let k' := isoWhiskerLeft (Cocone.toCostructuredArrow c ⋙ CostructuredArrow.pre α yoneda c.pt) k
  let k'' := HasColimit.isoOfNatIso k'
  refine' _ ≪≫ k''
  let u : colimit ((Cocone.toCostructuredArrow c ⋙ CostructuredArrow.pre α yoneda c.pt) ⋙ CostructuredArrow.toOver yoneda c.pt ⋙ Over.forget _) ≅ c.pt :=
    IsColimit.coconePointUniqueUpToIso (colimit.isColimit _) hc
  let v := preservesColimitIso (Over.forget _) ((Cocone.toCostructuredArrow c ⋙ CostructuredArrow.pre α yoneda c.pt) ⋙ CostructuredArrow.toOver yoneda c.pt)
  let w := v ≪≫ u
  refine' Over.isoMk w.symm _
  apply hc.hom_ext
  intro i
  simp [preservesColimitIso, IsColimit.coconePointUniqueUpToIso]
  erw [colimit.ι_desc_assoc]
  simp

end ArbitraryUniverses


end CategoryTheory
