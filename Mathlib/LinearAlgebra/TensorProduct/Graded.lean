/-
Copyright (c) 2023 Eric Wieser. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Eric Wieser
-/
import Mathlib.RingTheory.TensorProduct
import Mathlib.RingTheory.GradedAlgebra.Basic
import Mathlib.LinearAlgebra.DirectSum.TensorProduct
import Mathlib.Data.ZMod.Basic

/-!
# Graded tensor products over super- (`ZMod 2`-graded)

The graded product  $A \otimes B$ is defined on homogeneous tensors by

$$ (a \otimes b) \cdot (a' \otimes b') = (-1)^{\deg a' \deg b} (a \cdot a') \otimes (b \cdot b') $$

See also https://math.stackexchange.com/a/2024228/1896
-/

local notation "ℤ₂" => ZMod 2
open scoped TensorProduct

variable {R A B : Type*}

section external
variable (𝒜 : ZMod 2 → Type*) (ℬ : ZMod 2 → Type*)
variable [CommRing R]
variable [∀ i, AddCommGroup (𝒜 i)] [∀ i, AddCommGroup (ℬ i)]
variable [∀ i, Module R (𝒜 i)] [∀ i, Module R (ℬ i)]
variable [DirectSum.GRing 𝒜] [DirectSum.GRing ℬ]
variable [DirectSum.GAlgebra R 𝒜] [DirectSum.GAlgebra R ℬ]

instance (i : ℤ₂ × ℤ₂) : Module R (𝒜 (Prod.fst i) ⊗[R] ℬ (Prod.snd i)) :=
  TensorProduct.leftModule

instance : Pow ℤˣ (ZMod 2) where
  pow s z₂ := s ^ z₂.val

lemma z₂pow_def (s : ℤˣ) (x : ZMod 2) : s ^ x = s ^ x.val := rfl

@[simp] lemma z₂pow_zero (s : ℤˣ) : (s ^ (0 : ZMod 2) : ℤˣ) = (1 : ℤˣ) := pow_zero _
@[simp] lemma z₂pow_one (s : ℤˣ) : (s ^ (1 : ZMod 2) : ℤˣ) = s := pow_one _
lemma z₂pow_add (s : ℤˣ) (x y : ZMod 2) : s ^ (x + y) = s ^ x * s ^ y := by
  simp only [z₂pow_def]
  rw [ZMod.val_add, ←pow_eq_pow_mod, pow_add]
  fin_cases s <;> simp


local notation "𝒜ℬ" => (fun i : ℤ₂ × ℤ₂ => 𝒜 (Prod.fst i) ⊗[R] ℬ (Prod.snd i))
-- #exit
variable (R) in
noncomputable irreducible_def mulAux1 :
    (DirectSum _ 𝒜ℬ) →ₗ[R] (DirectSum _ 𝒜ℬ) →ₗ[R] (DirectSum _ 𝒜ℬ) := by
  refine TensorProduct.curry ?_
  refine ?_ ∘ₗ (TensorProduct.directSum R 𝒜ℬ 𝒜ℬ).toLinearMap
  refine DirectSum.toModule R _ _ fun i => ?_
  have o := DirectSum.lof R _ 𝒜ℬ (i.1.1 + i.2.1, i.1.2 + i.2.2)
  have s : ℤˣ := ((-1 : ℤˣ)^(i.1.2 * i.2.1 : ℤ₂) : ℤˣ)
  refine (s • o) ∘ₗ ?_
  refine ?_ ∘ₗ (TensorProduct.tensorTensorTensorComm R _ _ _ _).toLinearMap
  refine TensorProduct.map (TensorProduct.lift ?_) (TensorProduct.lift ?_)
  · exact DirectSum.gMulLHom R _
  · exact DirectSum.gMulLHom R _

open DirectSum (lof)
open GradedMonoid (GMul)

set_option maxHeartbeats 400000 in
@[simp]
theorem mulAux1_lof_tmul_lof_tmul (i₁ j₁ i₂ j₂ : ℤ₂)
    (a₁ : 𝒜 i₁) (b₁ : ℬ j₁) (a₂ : 𝒜 i₂) (b₂ : ℬ j₂) :
    mulAux1 R 𝒜 ℬ (lof R _ 𝒜ℬ (i₁, j₁) (a₁ ⊗ₜ b₁)) (lof R _ 𝒜ℬ (i₂, j₂) (a₂ ⊗ₜ b₂)) =
      (-1 : ℤˣ)^(j₁ * i₂)
        • lof R _ 𝒜ℬ (_, _) (GMul.mul a₁ a₂ ⊗ₜ GMul.mul b₁ b₂) := by
  rw [mulAux1]
  dsimp
  simp

set_option maxHeartbeats 4000000
variable (R) in
noncomputable irreducible_def mulAux :
    letI AB := (⨁ i, 𝒜 i) ⊗[R] (⨁ i, ℬ i)
    letI : Module R AB := TensorProduct.leftModule
    AB →ₗ[R] AB →ₗ[R] AB := by
  refine TensorProduct.curry ?_
  let e := TensorProduct.directSum R 𝒜 ℬ
  let e' := e.symm.toLinearMap
  refine e' ∘ₗ ?_
  refine ?_ ∘ₗ TensorProduct.map e.toLinearMap e.toLinearMap
  refine TensorProduct.lift ?_
  exact mulAux1 R 𝒜 ℬ

theorem mulAux_of_tmul_of (i₁ j₁ i₂ j₂ : ℤ₂)
    (a₁ : 𝒜 i₁) (b₁ : ℬ j₁) (a₂ : 𝒜 i₂) (b₂ : ℬ j₂) :
    mulAux R 𝒜 ℬ (lof R _ 𝒜 i₁ a₁ ⊗ₜ lof R _ ℬ j₁ b₁) (lof R _ 𝒜 i₂ a₂ ⊗ₜ lof R _ ℬ j₂ b₂) =
      (-1 : ℤˣ)^(j₁ * i₂)
        • (lof R _ 𝒜 _ (GMul.mul a₁ a₂) ⊗ₜ lof R _ ℬ _ (GMul.mul b₁ b₂)) := by
  rw [mulAux]
  dsimp only [TensorProduct.curry_apply, LinearMap.coe_comp, LinearEquiv.coe_coe, Function.comp_apply,
    TensorProduct.map_tmul, TensorProduct.lift.tmul]
  rw [TensorProduct.directSum_lof_tmul_lof, TensorProduct.directSum_lof_tmul_lof,
    mulAux1_lof_tmul_lof_tmul, Units.smul_def, zsmul_eq_smul_cast R, map_smul,
    TensorProduct.directSum_symm_lof_tmul, ←zsmul_eq_smul_cast, ←Units.smul_def]

theorem mulAux_one (x : (⨁ i, 𝒜 i) ⊗[R] (⨁ i, ℬ i)) :
    mulAux R 𝒜 ℬ 1 x = x := by
  suffices mulAux R 𝒜 ℬ 1 = LinearMap.id by
    exact FunLike.congr_fun this x
  ext ia a ib b
  dsimp only [LinearMap.coe_comp, Function.comp_apply, TensorProduct.AlgebraTensorModule.curry_apply,
    TensorProduct.curry_apply, LinearMap.coe_restrictScalars, LinearMap.id_coe, id_eq]
  rw [Algebra.TensorProduct.one_def]
  erw [mulAux_of_tmul_of]
  rw [zero_mul, z₂pow_zero, one_smul]
  simp_rw [DirectSum.lof_eq_of]
  rw [←DirectSum.of_mul_of, ←DirectSum.of_mul_of]
  erw [one_mul, one_mul]

theorem one_mulAux (x : (⨁ i, 𝒜 i) ⊗[R] (⨁ i, ℬ i)) :
    mulAux R 𝒜 ℬ x 1 = x := by
  suffices (mulAux R 𝒜 ℬ).flip 1 = LinearMap.id by
    exact FunLike.congr_fun this x
  ext
  dsimp
  rw [Algebra.TensorProduct.one_def]
  erw [mulAux_of_tmul_of]
  rw [mul_zero, z₂pow_zero, one_smul]
  simp_rw [DirectSum.lof_eq_of]
  rw [←DirectSum.of_mul_of, ←DirectSum.of_mul_of]
  erw [mul_one, mul_one]

theorem mulAux_assoc (x y z : (⨁ i, 𝒜 i) ⊗[R] (⨁ i, ℬ i)) :
    mulAux R 𝒜 ℬ (mulAux R 𝒜 ℬ x y) z = mulAux R 𝒜 ℬ x (mulAux R 𝒜 ℬ y z) := by
  let mA := mulAux R 𝒜 ℬ
    -- restate as an equality of morphisms so that we can use `ext`
  suffices LinearMap.llcomp R _ _ _ mA ∘ₗ mA =
      (LinearMap.llcomp R _ _ _ LinearMap.lflip <| LinearMap.llcomp R _ _ _ mA.flip ∘ₗ mA).flip by
    exact FunLike.congr_fun (FunLike.congr_fun (FunLike.congr_fun this x) y) z
  ext ixa xa ixb xb iya ya iyb yb iza za izb zb
  dsimp
  save
  simp_rw [mulAux_of_tmul_of, Units.smul_def, zsmul_eq_smul_cast R,
    LinearMap.map_smul₂, LinearMap.map_smul, mulAux_of_tmul_of, DirectSum.lof_eq_of,
    ←DirectSum.of_mul_of, mul_assoc]
  save
  simp_rw [←zsmul_eq_smul_cast R, ←Units.smul_def, smul_smul, ←z₂pow_add, add_mul, mul_add]
  congr 2
  abel

end external

section internal
variable [CommRing R] [Ring A] [Ring B] [Algebra R A] [Algebra R B]
variable (𝒜 : ZMod 2 → Submodule R A) (ℬ : ZMod 2 → Submodule R B)
variable [GradedAlgebra 𝒜] [GradedAlgebra ℬ]

open DirectSum


variable (R) in
def SuperTensorProduct
    (𝒜 : ZMod 2 → Submodule R A) (ℬ : ZMod 2 → Submodule R B)
    [GradedAlgebra 𝒜] [GradedAlgebra ℬ] :
    Type _ :=
  A ⊗[R] B

scoped[TensorProduct] notation:100 𝒜 " ⊗'[" R "] " ℬ:100 => SuperTensorProduct R 𝒜 ℬ

instance : AddCommGroupWithOne (𝒜 ⊗'[R] ℬ) := Algebra.TensorProduct.instAddCommGroupWithOne
instance : Module R (𝒜 ⊗'[R] ℬ) := TensorProduct.leftModule

local notation "↥" P => { x // x ∈ P}

def mul : (𝒜 ⊗'[R] ℬ) →ₗ[R] (𝒜 ⊗'[R] ℬ) →ₗ[R] (𝒜 ⊗'[R] ℬ) := by
  let fA := (decomposeAlgEquiv 𝒜).toLinearEquiv
  let fB := (decomposeAlgEquiv ℬ).toLinearEquiv
  let fAB1 := TensorProduct.congr fA fB
  let fAB2 := TensorProduct.directSum R (𝒜 ·) (ℬ ·)
  let fAB := fAB1 ≪≫ₗ fAB2
  let fAB' := TensorProduct.congr fAB fAB
  letI tAB := fun i : ZMod 2 × ZMod 2 => 𝒜 i.1 ⊗[R] ℬ i.2
  let fAB'' := fAB' ≪≫ₗ TensorProduct.directSum R tAB tAB
  -- refine TensorProduct.curry ?_
  -- refine ?_ ∘ₗ TensorProduct.map fAB.toLinearMap fAB.toLinearMap
  -- `(a_i ⊗ b_j) * (a_k ⊗ b_l) = -1^(jk) • (a_i*a_k ⊗ b_j*b_l)``

  -- refine TensorProduct.uncurry R _ _ _ ∘ₗ TensorProduct.lift ?_
  -- refine TensorProduct.homTensorHomMap R A B A B ∘ₗ TensorProduct.lift ?_
  sorry
