export DISPLAY=:0
for ent_coef in "0.001"; do
    for run in "run1" "run2" "run3" "run4" "run5"; do
        python3 run_stable_baselines.py --randomize_engagement --turnframes 10 --ent_coef ${ent_coef} Toribash-DestroyUke-v1 trpo destroyukev1_trpo_entcoef_${ent_coef}_turnframes_10_${run} &
    done
done
