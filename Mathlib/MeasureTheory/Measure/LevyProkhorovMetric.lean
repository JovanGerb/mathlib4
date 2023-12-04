/-
Copyright (c) 2023 Kalle Kytölä. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kalle Kytölä
-/
import Mathlib.MeasureTheory.Measure.ProbabilityMeasure

/-!
# The Lévy-Prokhorov distance on spaces of finite measures and probability measures

## Main definitions

* `MeasureTheory.levyProkhorovEDist`: The Lévy-Prokhorov distance between two measures.

## Main results

* `levyProkhorovEDist.pseudoEMetricSpace_finiteMeasure`: The Lévy-Prokhorov distance is a
  pseudoemetric on the space of finite measures.
* `levyProkhorovEDist.pseudoEMetricSpace_probabilityMeasure`: The Lévy-Prokhorov distance is a
  pseudoemetric on the space of probability measures.

## Todo

* Show that in Borel spaces, the Lévy-Prokhorov distance is a metric; not just a pseudometric.
* Prove that if `X` is metrizable and separable, then the Lévy-Prokhorov distance metrizes the
  topology of weak convergence.

## Tags

finite measure, probability measure, weak convergence, convergence in distribution, metrizability
-/

open Topology Metric Filter Set ENNReal NNReal

namespace MeasureTheory

open scoped Topology ENNReal NNReal BoundedContinuousFunction

section Levy_Prokhorov

/-! ### Lévy-Prokhorov metric -/

variable {ι : Type*} {Ω : Type*} [MeasurableSpace Ω]
variable [MetricSpace Ω] [OpensMeasurableSpace Ω]

/-- The Lévy-Prokhorov distance on the space of finite measures:
`d(μ,ν) = inf {r ≥ 0 | ∀ B, μ B ≤ ν Bᵣ + r ∧ ν B ≤ μ Bᵣ + r}`. -/
noncomputable def levyProkhorovEDist (μ ν : Measure Ω) : ℝ≥0∞ :=
  sInf {ε | ∀ B, MeasurableSet B →
            μ B ≤ ν (thickening ε.toReal B) + ε ∧ ν B ≤ μ (thickening ε.toReal B) + ε}

lemma measure_apply_le_of_le_of_forall_le_measure_thickening_add {ε₁ ε₂ : ℝ≥0∞} (μ ν : Measure Ω)
    (h_le : ε₁ ≤ ε₂) (hε₁ : ∀ B, MeasurableSet B → μ B ≤ ν (thickening ε₁.toReal B) + ε₁)
    {B : Set Ω} (B_mble : MeasurableSet B) :
    μ B ≤ ν (thickening ε₂.toReal B) + ε₂ := by
  specialize hε₁ B B_mble
  by_cases ε_top : ε₂ = ∞
  · simp only [ne_eq, FiniteMeasure.ennreal_coeFn_eq_coeFn_toMeasure, ε_top, top_toReal,
                add_top, le_top]
  apply hε₁.trans (add_le_add ?_ h_le)
  simp only [FiniteMeasure.ennreal_coeFn_eq_coeFn_toMeasure] at *
  exact measure_mono (μ := ν) (thickening_mono (toReal_mono ε_top h_le) B)

lemma left_measure_le_of_levyProkhorovEDist_lt {μ ν : Measure Ω} {c : ℝ≥0∞}
    (h : levyProkhorovEDist μ ν < c) {B : Set Ω} (B_mble : MeasurableSet B) :
    μ B ≤ ν (thickening c.toReal B) + c := by
  obtain ⟨c', ⟨hc', lt_c⟩⟩ := sInf_lt_iff.mp h
  apply measure_apply_le_of_le_of_forall_le_measure_thickening_add μ ν lt_c.le _ B_mble
  exact fun s s_mble ↦ (hc' s s_mble).1

lemma right_measure_le_of_levyProkhorovEDist_lt {μ ν : Measure Ω} {c : ℝ≥0∞}
    (h : levyProkhorovEDist μ ν < c) {B : Set Ω} (B_mble : MeasurableSet B) :
    ν B ≤ μ (thickening c.toReal B) + c := by
  obtain ⟨c', ⟨hc', lt_c⟩⟩ := sInf_lt_iff.mp h
  apply measure_apply_le_of_le_of_forall_le_measure_thickening_add ν μ lt_c.le _ B_mble
  exact fun s s_mble ↦ (hc' s s_mble).2

lemma levyProkhorovEDist_le_of_forall (μ ν : Measure Ω) (δ : ℝ≥0∞)
    (h : ∀ ε B, δ < ε → ε < ∞ → MeasurableSet B →
      μ B ≤ ν (thickening ε.toReal B) + ε ∧ ν B ≤ μ (thickening ε.toReal B) + ε) :
    levyProkhorovEDist μ ν ≤ δ := by
  apply ENNReal.le_of_forall_pos_le_add
  intro ε hε δ_lt_top
  by_cases ε_top : ε = ∞
  · simp only [ε_top, add_top, le_top]
  apply sInf_le
  simp only [ne_eq, FiniteMeasure.ennreal_coeFn_eq_coeFn_toMeasure, mem_setOf_eq]
  intro B B_mble
  convert h (δ + ε) B ?_ ?_ B_mble
  · simpa only [add_zero] using ENNReal.add_lt_add_left (a := δ) δ_lt_top.ne (coe_pos.mpr hε)
  · simp only [add_lt_top, δ_lt_top, coe_lt_top, and_self]

lemma levyProkhorovEDist_le_of_forall_add_pos_le (μ ν : Measure Ω) (δ : ℝ≥0∞)
    (h : ∀ ε B, 0 < ε → ε < ∞ → MeasurableSet B →
      μ B ≤ ν (thickening (δ + ε).toReal B) + δ + ε ∧
      ν B ≤ μ (thickening (δ + ε).toReal B) + δ + ε) :
    levyProkhorovEDist μ ν ≤ δ := by
  apply levyProkhorovEDist_le_of_forall μ ν δ
  intro x B δ_lt_x x_lt_top B_mble
  have pos : 0 < x - δ := by exact tsub_pos_of_lt δ_lt_x
  simpa [add_assoc, add_tsub_cancel_of_le δ_lt_x.le]
    using h (x - δ) B pos (tsub_lt_of_lt x_lt_top) B_mble

lemma levyProkhorovEDist_le_max_measure_univ (μ ν : Measure Ω) :
    levyProkhorovEDist μ ν ≤ max (μ univ) (ν univ) := by
  apply sInf_le
  simp only [ENNReal.coe_max, FiniteMeasure.ennreal_mass, ge_iff_le, ne_eq,
    FiniteMeasure.ennreal_coeFn_eq_coeFn_toMeasure, mem_setOf_eq]
  intro B _
  refine ⟨(measure_mono (subset_univ B)).trans ?_, (measure_mono (subset_univ B)).trans ?_⟩
  · apply le_add_left
    apply le_max_left
  · apply le_add_left
    apply le_max_right

lemma levyProkhorovEDist_lt_top (μ ν : Measure Ω) [IsFiniteMeasure μ] [IsFiniteMeasure ν] :
    levyProkhorovEDist μ ν < ∞ := by
  apply lt_of_le_of_lt (levyProkhorovEDist_le_max_measure_univ μ ν)
  exact (max_lt IsFiniteMeasure.measure_univ_lt_top IsFiniteMeasure.measure_univ_lt_top)

lemma levyProkhorovEDist_self (μ : Measure Ω) :
    levyProkhorovEDist μ μ = 0 := by
  by_cases zero_meas : μ = 0
  · simp [zero_meas, levyProkhorovEDist, FiniteMeasure.toMeasure_zero]
  simp_rw [← Measure.measure_univ_eq_zero] at zero_meas
  apply sInf_eq_of_forall_ge_of_forall_gt_exists_lt (by simp)
  simp only [ne_eq, FiniteMeasure.ennreal_coeFn_eq_coeFn_toMeasure, and_self, mem_setOf_eq]
  intro ε ε_pos
  by_cases ε_infty : ε = ∞
  · refine ⟨1, ?_, by simp only [ε_infty, one_lt_top]⟩
    exact fun B _ ↦ le_add_right (measure_mono (self_subset_thickening (by simp) B))
  have half_ε_pos : 0 < ε/2 := by
    simp only [ENNReal.div_pos_iff, ne_eq, ε_pos.ne.symm, not_false_eq_true, two_ne_top, and_self]
  have half_ε_lt_top : ε/2 < ∞ := div_lt_top ε_infty two_ne_zero
  refine ⟨min (ε/2) (μ univ), ⟨?_, ?_⟩⟩
  · intro B _
    apply le_add_right (measure_mono (self_subset_thickening ?_ B))
    apply ENNReal.toReal_pos
    · exact (lt_min half_ε_pos (zero_lt_iff.mpr zero_meas)).ne.symm
    · exact (lt_of_le_of_lt (min_le_left _ _) half_ε_lt_top).ne
  · apply lt_of_le_of_lt (min_le_left _ _)
    simpa only [gt_iff_lt, zero_add, ENNReal.add_halves]
      using ENNReal.add_lt_add_right half_ε_lt_top.ne half_ε_pos

lemma levyProkhorovEDist_comm (μ ν : Measure Ω) :
    levyProkhorovEDist μ ν = levyProkhorovEDist ν μ := by
  rw [levyProkhorovEDist]
  congr
  ext ε
  simp only [ne_eq, FiniteMeasure.ennreal_coeFn_eq_coeFn_toMeasure, mem_setOf_eq]
  refine ⟨?_, ?_⟩ <;>
  · intro h B B_mble
    specialize h B B_mble
    refine ⟨h.2, h.1⟩

lemma levyProkhorovEDist_triangle (μ ν κ : Measure Ω) :
    levyProkhorovEDist μ κ ≤ levyProkhorovEDist μ ν + levyProkhorovEDist ν κ := by
  by_cases LPμν_finite : levyProkhorovEDist μ ν = ∞
  · simp [LPμν_finite]
  by_cases LPνκ_finite : levyProkhorovEDist ν κ = ∞
  · simp [LPνκ_finite]
  apply levyProkhorovEDist_le_of_forall_add_pos_le
  intro ε B ε_pos ε_lt_top B_mble
  simp only [ne_eq, FiniteMeasure.ennreal_coeFn_eq_coeFn_toMeasure] at *
  have half_ε_pos : 0 < ε / 2 := by
    simp only [ENNReal.div_pos_iff, ne_eq, ε_pos.ne.symm, not_false_eq_true, two_ne_top, and_self]
  let r := levyProkhorovEDist μ ν + ε / 2
  let s := levyProkhorovEDist ν κ + ε / 2
  have lt_r : levyProkhorovEDist μ ν < r := lt_add_right LPμν_finite half_ε_pos.ne.symm
  have lt_s : levyProkhorovEDist ν κ < s := lt_add_right LPνκ_finite half_ε_pos.ne.symm
  refine ⟨?_, ?_⟩
  · have obs₁ := left_measure_le_of_levyProkhorovEDist_lt lt_r B_mble
    have mble_B₁ : MeasurableSet (thickening (ENNReal.toReal r) B) :=
      isOpen_thickening.measurableSet
    have obs₂ := left_measure_le_of_levyProkhorovEDist_lt lt_s mble_B₁
    simp only [ENNReal.div_pos_iff, ne_eq, and_true, gt_iff_lt,
      FiniteMeasure.ennreal_coeFn_eq_coeFn_toMeasure, ge_iff_le] at *
    apply obs₁.trans
    apply (add_le_add_right obs₂ _).trans
    simp_rw [add_assoc, add_comm (ε / 2), add_assoc, ENNReal.add_halves]
    simp_rw [← add_assoc (levyProkhorovEDist _ _),
             add_comm (levyProkhorovEDist μ ν) (levyProkhorovEDist ν κ)]
    congr
    apply add_le_add_right (measure_mono _)
    apply (thickening_thickening_subset _ _ _).trans (thickening_mono _ _)
    rw [← ENNReal.toReal_add]
    · simp_rw [add_assoc, add_comm (ε / 2), add_assoc, ENNReal.add_halves, ← add_assoc]
      exact Eq.le rfl
    · simp only [add_ne_top]
      refine ⟨ne_top_of_lt lt_s, (ENNReal.div_lt_top ε_lt_top.ne two_ne_zero).ne⟩
    · simp only [add_ne_top]
      refine ⟨ne_top_of_lt lt_r, (ENNReal.div_lt_top ε_lt_top.ne two_ne_zero).ne⟩
  · have obs₁ := right_measure_le_of_levyProkhorovEDist_lt lt_s B_mble
    have mble_B₁ : MeasurableSet (thickening (ENNReal.toReal s) B) :=
      isOpen_thickening.measurableSet
    have obs₂ := right_measure_le_of_levyProkhorovEDist_lt lt_r mble_B₁
    simp only [ENNReal.div_pos_iff, ne_eq, and_true, gt_iff_lt,
      FiniteMeasure.ennreal_coeFn_eq_coeFn_toMeasure, ge_iff_le] at *
    apply obs₁.trans
    apply (add_le_add_right obs₂ _).trans
    simp_rw [add_assoc, add_comm (ε / 2), add_assoc, ENNReal.add_halves]
    simp_rw [← add_assoc (levyProkhorovEDist _ _),
             add_comm (levyProkhorovEDist μ ν) (levyProkhorovEDist ν κ)]
    congr
    apply add_le_add_right (measure_mono _)
    apply (thickening_thickening_subset _ _ _).trans (thickening_mono _ _)
    rw [← ENNReal.toReal_add]
    · simp_rw [add_assoc, add_comm (ε / 2), add_assoc, ENNReal.add_halves, ← add_assoc]
      rw [add_comm (levyProkhorovEDist _ _)]
    · simp only [add_ne_top]
      refine ⟨ne_top_of_lt lt_r, (ENNReal.div_lt_top ε_lt_top.ne two_ne_zero).ne⟩
    · simp only [add_ne_top]
      refine ⟨ne_top_of_lt lt_s, (ENNReal.div_lt_top ε_lt_top.ne two_ne_zero).ne⟩

/-- The Lévy-Prokhorov distance `levyProkhorovEDist` makes `FiniteMeasure X` a pseudoemetric
space. -/
noncomputable def levyProkhorovEDist_pseudoEMetricSpace_finiteMeasure :
    PseudoEMetricSpace (FiniteMeasure Ω) where
  edist μ ν := levyProkhorovEDist μ.toMeasure ν.toMeasure
  edist_self μ := levyProkhorovEDist_self μ.toMeasure
  edist_comm μ ν := levyProkhorovEDist_comm μ.toMeasure ν.toMeasure
  edist_triangle μ ν κ := levyProkhorovEDist_triangle μ.toMeasure ν.toMeasure κ.toMeasure

/-- The Lévy-Prokhorov distance `levyProkhorovEDist` makes `ProbabilityMeasure Ω` a pseudoemetric
space. -/
noncomputable def levyProkhorovEDist_pseudoEMetricSpace_probabilityMeasure :
    PseudoEMetricSpace (ProbabilityMeasure Ω) where
  edist μ ν := levyProkhorovEDist μ.toMeasure ν.toMeasure
  edist_self μ := levyProkhorovEDist_self μ.toMeasure
  edist_comm μ ν := levyProkhorovEDist_comm μ.toMeasure ν.toMeasure
  edist_triangle μ ν κ := levyProkhorovEDist_triangle μ.toMeasure ν.toMeasure κ.toMeasure

end Levy_Prokhorov --section

end MeasureTheory -- namespace
