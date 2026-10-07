# E prompts (E1-E3)
Copy to `docs/opencode_master_prompts/delta/`. Run one at a time from `niaverp`, in order, with the strongest model you have (`-m provider/model`):
opencode run -f ..\docs\opencode_master_prompts\delta\E1_make_app_start_on_device.md "Execute the attached prompt exactly."
Then E2, then E3. Send back each RESULT file. Next to any results file with PASS, also run a fresh session with a different model:
"Verify every claim in docs/implementation/RESULT_E<n>_*.md against the code; list anything marked PASS that is not proven."
