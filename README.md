# MGI imaging analysis

MATLAB code for the multi-GRIN imaging (M1, DMS, VLT) analyses of baseline sessions, of the Baseline → TD and TD → TBZ comparisons, and of activity around voluntary licks (VL) and tongue protrusions (TP). It reads the condition files written by `MGI_data_export` (`BLS.mat`, `DW.mat`, `TBZ.mat`, `BLL.mat`). The VL/TP analysis needs the supervised tongue-protrusion bouts (`behavior.tongueProtrusion`) that the exporter writes for BLL, DW and TBZ.

## Requirements

MATLAB R2019b or later with the Statistics and Machine Learning Toolbox (`linkage` and `cluster` order the correlation matrices; `fitlme`, `kstest2` and `pdist` are used when available).

## Data

The condition files are not part of the repository. Set `cfg.paths.data` in `config/mgi_config.m` to the folder that holds them, or pass it at run time (see below). Results are written to `results/` inside the repository unless `cfg.paths.results` is set.

## Run

```matlab
cd MGI_imaging_analysis               % repository folder
mgi_setup();
baseline = run_baseline();            % BLS: coupling, partial correlations, preference, correlation matrices
changes  = run_condition_changes();   % Baseline vs TD and TD vs TBZ: transient rates, correlation changes
vltp     = run_vl_tp();               % BLL (VL) and DW (TP): event-aligned activity, epoch AUC
```

Each run function loads the data, preprocesses it, saves the preprocessed results and statistics, and draws the figures. The two halves can also be run separately:

```matlab
cfg = mgi_config();
results = mgi_preprocess_baseline(cfg);                                        % preprocessing
mgi_plot_baseline(fullfile(cfg.paths.preprocessed,'baseline.mat'),cfg);         % plotting only
```

Settings are in `config/mgi_config.m`. Any of them can be overridden without editing the file:

```matlab
run_baseline(struct('paths',struct('data','D:\exported_imaging','results','D:\mgi_results'), ...
                    'baseline',struct('preferenceShuffles',2000)));
```

## Layout

```
run_baseline.m, run_condition_changes.m,
run_vl_tp.m                                load -> preprocess -> plot
mgi_setup.m                                adds the folders below to the path
config/          mgi_config (paths, cohorts, parameters, colors, figure style)
loading/         mgi_session_index, mgi_find_sessions, mgi_load_session, mgi_load_sessions
preprocessing/   preprocessing code: mgi_preprocess_baseline, mgi_preprocess_condition_changes,
                 mgi_preprocess_vl_tp
  functions/     preprocessing functions (raw session -> digestible variables -> analyses, statistics)
plotting/        plotting code: mgi_plot_baseline, mgi_plot_condition_changes, mgi_plot_vl_tp
  functions/     plotting functions (one per figure) and drawing helpers
tests/           synthetic data in the exported format and run_tests
results/         preprocessed/, statistics/, figures/ (created on first run)
```

## Loading

```matlab
cfg = mgi_config();
index    = mgi_session_index('BLS',cfg);                     % every session in BLS.mat
rows     = mgi_find_sessions('DW',cfg,'Cohort','WT');         % WT, TBZ, D1, D2, CHAT or 'all'
rows     = mgi_find_sessions('BLS',cfg,'Mouse',{'Pan_11'});
session  = mgi_load_session('BLS','Pan_11',cfg);              % by mouse, condition index or index row
sessions = mgi_load_sessions('TBZ',cfg,'Cohort','all');
```

Cohort membership uses the global mouse index and the cohort definitions stored in each condition file. Only the requested session variable is read from disk.

## Preprocessing

Raw session → digestible variables (`mgi_session_inputs`, `mgi_session_features`, `mgi_event_onsets`):

| Variable | Function | Definition |
|---|---|---|
| z-scored activity | `mgi_zscore_activity` | CNMF-E denoised trace of each neuron z-scored over the session |
| orofacial speed | `mgi_orofacial_speed` | frame-to-frame displacement of keypoints 1–5 and 8 (behavior camera), averaged across tracked keypoints; averaged within each imaging frame (frame edges from `neuralFrameLocs`); frames with < 50% tracked samples invalid; gaps ≤ 250 ms interpolated; 1 s centered moving mean; z-scored |
| analysis frames | `mgi_common_frames` | frames with valid speed and finite activity in all regions; each neuron and the speed re-standardized on those frames |
| transient rate | `mgi_transient_rate` | deconvolved signal summed over the session ÷ median non-zero event amplitude ÷ duration (typical events s⁻¹) |
| event onsets | `mgi_event_onsets` | imaging frame (`startNeuralFrame`) of each supervised tongue-protrusion bout: voluntary licks in BLL, tongue protrusions in DW; bouts outside the imaged period are left out; analyses use the imaging frames with behavior time (`syncedNeuralFrames`) |

Baseline analyses (WT mice, BLS):

| Output | Function | Definition |
|---|---|---|
| movement coupling | `mgi_movement_coupling` | R² of each neuron with orofacial speed; P from 1,000 circular shifts (≥ 5 s); significant neurons BH-corrected within mouse and region, counted over all recorded neurons |
| within-region partial R² | `mgi_pairwise_r2`, `mgi_conditioning_basis` | every unique within-region pair after regressing out the top 5 temporal PCs of the other two regions |
| between-region partial r | `mgi_inter_partial_r` | signed r of each neuron with the mean activity of each target region, both residualized on the top 5 PCs of the third region (`baseline.interConditioning = 'mean'` uses the third region's mean activity instead) |
| region preference | `mgi_preference_null` | difference of the two partial r values against 20,000 distinct circular shifts of the neuron (two-sided around the null mean); BH within mouse and seed region; significant neurons assigned to the target favored by the observed difference relative to the null mean |
| correlation matrices | `mgi_correlation_matrix` | R² between all neurons of a session (all BLS sessions); neurons ordered within region by Ward clustering into 4 clusters |
| statistics | `mgi_baseline_summary` | pooled-neuron two-sample KS between regions (movement R²); mouse-level sign-flip test of the KS statistic, BH (within-region partial R²); one-sample t-test of mouse centroid residuals, Holm (between-region partial r) |

Condition comparisons (`cfg.comparisons`): Baseline (BLS) → TD (DW) in WT mice, and TD (DW) → TBZ in the TBZ cohort.

| Output | Function | Definition |
|---|---|---|
| transient rates | `mgi_transient_rate_comparison` | neurons with ≥ 10 events; rate ~ condition + (1\|mouse), ML; design-effect s.e.m.; 30-bin proportions up to the 97.5th percentile of the pooled rates. Pan_4 is left out of Baseline → TD |
| correlation change | `mgi_correlation_change` | R² of every within-region pair and every between-region pair on the analysis frames; CDF per mouse on an asinh(R²/0.002) grid; mouse-averaged difference before − after; pooled-pair two-sample KS, BH across the curves of a panel |

VL and TP (`cfg.events`): BLL (VL) and DW (TP) sessions of the WT (pan-neuronal) cohort, neurons pooled across mice within region.

| Output | Function | Definition |
|---|---|---|
| event-aligned activity | `mgi_event_average` | z-scored activity of each neuron averaged over events from −15 to +15 s (samples outside the recording left out) |
| epoch AUC | `mgi_event_windows`, `mgi_epoch_auc` | pre-movement (frames −60 to −1, −3 to 0 s) and post-movement (frames 0 to 59, 0 to +3 s) epochs: mean activity × 3 s per event (≥ 80% finite frames), averaged over events (≥ 3 valid events) |
| shift control | `mgi_event_shift_null`, `mgi_event_activity` | the whole onset train circularly shifted by one random lag (≥ 10 s from zero) per draw, 1,000 draws; per neuron, the mean of the pre and post AUC of one draw chosen at random among its finite draws |
| population summary | `mgi_event_summary` | mean ± s.e.m. across neurons (s.d./√n); traces display-smoothed with a centered 1 s moving mean; neurons sorted by time to peak within each condition |
| statistics | `mgi_event_summary`, `mgi_ranksum` | two-sided Wilcoxon rank-sum, TP vs VL at each epoch (shift control, pre, post), Benjamini–Hochberg across the three epochs |

Random draws use one stream seeded by `cfg.events.seed`, in the order session → region → VL, TP.

## Figures

`results/figures/baseline/`

| File | Content |
|---|---|
| `movement_correlation_cdf` | CDF of single-neuron R² with orofacial movement |
| `movement_significant_proportion` | proportion of neurons correlated with orofacial movement |
| `correlation_matrix_Pan_11` | R² correlation matrix of one session (`cfg.figures.correlogramMouse`) |
| `intra_region_partial_correlation_cdf` | CDF of pairwise within-region partial R², averaged across mice |
| `inter_region_partial_correlation_scatter` | signed between-region partial r with mouse medians |
| `region_preference_proportion` | proportion of neurons with a single-region preference |

`results/figures/baseline_td/` and `results/figures/td_tbz/`

| File | Content |
|---|---|
| `<comparison>_transient_rate_<region>` | Ca²⁺ transient-rate distributions |
| `<comparison>_inter_region_correlation_change` | ΔCDF of between-region pairwise R² |
| `<comparison>_intra_region_correlation_change` | ΔCDF of within-region pairwise R² |

`results/figures/vl_tp/`

| File | Content |
|---|---|
| `vl_tp_activity_<region>` | mean z-scored activity ± s.e.m. around VL and TP onset (−15 to +15 s; pre and post epochs shaded) and heatmaps of every neuron's event-averaged activity sorted by time to peak |
| `vl_tp_epoch_auc_<region>` | mean ± s.e.m. AUC of the shift control, pre- and post-movement epochs for TP and VL |

Formats are set by `cfg.figures.formats` (PNG at 600 dpi, SVG, PDF, FIG). Any correlation matrix can be drawn with `mgi_plot_correlogram(results.correlation,cfg,folder,'<mouse>')`.

## Saved results

- `results/preprocessed/baseline.mat` (`results.baseline`, `results.correlation`, `results.config`)
- `results/preprocessed/condition_changes.mat` (`results.comparisons`, `results.config`)
- `results/preprocessed/vl_tp.mat` (`results.regions`, `results.sessions`, `results.config`)
- `results/statistics/*.csv`: test tables, region summaries and neuron-level values

## Tests

```matlab
cd tests; run_tests
```

The tests write small synthetic `BLS.mat`, `DW.mat`, `TBZ.mat` and `BLL.mat` files in the exported format and check:

- loading and cohort selection;
- the orofacial speed against an independent implementation;
- the circular-shift nulls and the event-aligned activity against direct computation;
- the statistical primitives;
- the complete baseline, comparison and VL/TP pipelines, including all figures.

They pass in GNU Octave 8.4 (with the statistics package).
