# Data Augmentation Techniques for Genome Data in DeepVariant Fine-Tuning

## Introduction

This document investigates data augmentation techniques applicable to genomic data for fine-tuning DeepVariant, a deep learning-based variant caller. DeepVariant processes BAM files into pileup images and uses convolutional neural networks to identify SNPs and indels. Data augmentation can improve model robustness, address class imbalance, and enhance generalization, especially when fine-tuning on limited or specific datasets.

The investigation is based on the cloned repository (https://github.com/sphussey/DeepVariant-Fine-Tuning), which configures transfer learning for DeepVariant using NVIDIA Parabricks. The project uses GIAB benchmark samples (HG001-HG005) with resampling strategies to balance variant types.

## Overview of DeepVariant and Fine-Tuning Context

DeepVariant converts genomic alignments (BAM) into multi-channel images:
- **Width**: Genomic window (e.g., 100bp)
- **Height**: Stacked reads
- **Channels**: Base calls (A/C/G/T), quality scores, strand, mapping quality

Fine-tuning involves transfer learning from a pre-trained model, using additional samples and resampling to handle class imbalance (e.g., SNVs vs. indels).

## Data Augmentation Categories

### 1. Sequence-Level Augmentations

These modify the underlying genomic sequences or reads before pileup generation.

#### 1.1 Read Simulation & Synthetic Variants
- **Description**: Use simulators like ART or Mason to generate synthetic reads with controlled variants.
- **Pros**: Unlimited labeled data; addresses rarity of complex indels.
- **Cons**: May not capture real sequencing biases.
- **Relevance**: High for rare variant training.
- **Reference**: Li et al. (2012) - ART simulator.

#### 1.2 Basecall Quality Score Perturbation
- **Description**: Randomly adjust Phred quality scores (±1-3).
- **Pros**: Improves cross-platform robustness.
- **Cons**: Minimal impact if data is well-calibrated.
- **Relevance**: Medium.

#### 1.3 Allele Frequency Manipulation
- **Description**: Reweight read distributions to vary heterozygous/homozygous ratios.
- **Pros**: Handles depth fluctuations.
- **Cons**: Risk of implausible frequencies.
- **Relevance**: Medium for rare variants.

### 2. Image-Level Augmentations (Pileup Images)

Directly augment the CNN input images.

#### 2.1 Spatial Transforms (Position Jittering)
- **Description**: Shift genomic window (±5-10bp) or mirror around variant.
- **Pros**: Translation invariance; tested in DeepVariant.
- **Cons**: May lose positional information.
- **Relevance**: Medium-High.
- **Reference**: Poplin et al. (2016) - DeepVariant paper.

#### 2.2 Channel Perturbations
- **Description**: Add noise to quality or mapping quality channels.
- **Pros**: Simulates data variability.
- **Cons**: Limited improvement.
- **Relevance**: Low-Medium.

#### 2.3 Brightness/Contrast Adjustment
- **Description**: Scale pixel values or add noise.
- **Pros**: Accounts for coverage bias.
- **Cons**: Pileups are normalized; minimal benefit.
- **Relevance**: Low.

### 3. Training-Time Augmentations

Applied during model training.

#### 3.1 Online Hard Negative Mining (OHNM)
- **Description**: Focus on misclassified regions.
- **Pros**: Improves rare variant detection.
- **Cons**: Increases training time.
- **Relevance**: Very High.

#### 3.2 Mixup (Sample Interpolation)
- **Description**: Interpolate between samples with blended labels.
- **Pros**: Better generalization.
- **Cons**: Intermediate labels may be invalid.
- **Relevance**: Medium.

#### 3.3 Class Rebalancing & Focal Loss
- **Description**: Use focal loss to emphasize hard examples.
- **Pros**: Addresses imbalance (already in config).
- **Cons**: Requires tuning.
- **Relevance**: Critical.
- **Reference**: Lin et al. (2017) - Focal Loss.

#### 3.4 Curriculum Learning
- **Description**: Train on easy variants first, then hard.
- **Pros**: Stabilizes training.
- **Cons**: Added complexity.
- **Relevance**: Medium.

### 4. Data-Level Augmentations

Modify datasets at preprocessing stage.

#### 4.1 Sample Pooling
- **Description**: Mix BAMs from multiple samples.
- **Pros**: Increases effective size; reduces bias.
- **Cons**: Artificial frequencies.
- **Relevance**: Medium.

#### 4.2 Resampling (Already Implemented)
- Current config: 4:1:1:1 SNV:indel ratios.
- Enhancements: Inverse frequency weighting.

## Recommended Pipeline

**Tier 1 (High Priority):**
1. Class rebalancing (done).
2. Hard negative mining.
3. Quality perturbation.
4. Position jittering.

**Tier 2 (Medium):**
5. Synthetic simulation.
6. Curriculum learning.
7. Mixup.

**Tier 3 (Low):**
8. Channel perturbations.
9. Sample pooling.

## Evaluation and Next Steps

Use hap.py for benchmarking (Precision, Recall, F1). Ablate augmentations on validation set (HG001), test on held-out (HG002, HG005).

Integrate augmentations into training scripts. Monitor for overfitting and biological validity.

## References

- Poplin et al. (2016) - DeepVariant.
- Lin et al. (2017) - Focal Loss.
- Li et al. (2012) - ART.
- Bengio et al. (2009) - Curriculum Learning.