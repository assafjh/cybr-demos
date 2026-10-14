# conjur-summon-bin
Carrier image for the `summon` mode of [conjur-injector](../conjur-injector).

Contains only static `summon` and `summon-conjur` binaries under `/summon`. The injector adds it to a pod as an init container that copies them into an in-memory volume, then wraps the app command with summon - so the app gets its secrets as environment variables **without rebuilding the app image or changing CI**.

- linux/amd64 only (summon-conjur has no linux/arm64 release).
- Versions are build args: `SUMMON_VERSION`, `SUMMON_CONJUR_VERSION`.
- Smoke test runs both binaries inside busybox, which proves they are statically linked.
