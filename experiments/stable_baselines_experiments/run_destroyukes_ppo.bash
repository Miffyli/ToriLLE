export DISPLAY=:0
for ent_coef in "0.001"; do
    for run in "run1" "run2" "run3" "run4" "run5"; do
        python3 run_stable_baselines.py --num_envs 1 --randomize_engagement --turnframes 10 --steps_per_batch 1024 --ent_coef ${ent_coef} Toribash-DestroyUke-v1 ppo destroyukev1_ppo_entcoef_${ent_coef}_batch_1024_envs_1_turnframes_10_${run} &
    done
done
