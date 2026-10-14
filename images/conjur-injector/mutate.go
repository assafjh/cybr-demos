package main

import (
	"encoding/json"
	"fmt"
	"sort"
	"strings"
)

// Injector annotations - only what the Secrets Provider has no annotation for.
// Everything else is the provider's own annotation set (conjur.org/container-mode,
// secrets-destination, conjur-secrets.*, secret-file-path.*, k8s-secrets...), which the
// injector reads for placement and otherwise passes through untouched.
const (
	annInject           = "conjur.org/inject"            // "true" to opt in
	annInjectType       = "conjur.org/inject-type"       // secrets-provider (default) | summon
	annInjectMountPath  = "conjur.org/inject-mount-path" // destination=file: where app containers see the files (default /conjur/secrets)
	annInjectContainers = "conjur.org/inject-containers" // comma-separated app containers to inject into (default: all)
	annSummonSecrets    = "conjur.org/summon-secrets"    // summon: secrets.yml content
	annSummonCommand    = "conjur.org/summon-command"    // summon: original command when the manifest has none

	// Written by the injector
	annStatus   = "conjur.org/inject-status"
	annIdentity = "conjur.org/inject-identity"

	// Standard Secrets Provider annotations the injector reads
	annContainerMode  = "conjur.org/container-mode"      // sidecar | init
	annDestination    = "conjur.org/secrets-destination" // file | k8s_secrets
	annK8sSecrets     = "conjur.org/k8s-secrets"
	annRefreshEnabled = "conjur.org/secrets-refresh-enabled"
	annSecretsPrefix  = "conjur.org/conjur-secrets."
	annSecretsPrefix2 = "conjur.org/conjur-secrets-policy-path."

	typeProvider = "secrets-provider"
	typeSummon   = "summon"

	providerName   = "conjur-secrets-provider"
	summonInitName = "conjur-summon-init"

	volPodInfo   = "conjur-podinfo"
	volSecrets   = "conjur-secrets"
	volJWT       = "conjur-jwt-token"
	volSummonBin = "conjur-summon-bin"
	volSummonCfg = "conjur-summon-config"

	providerSecretsDir = "/conjur/secrets"
	jwtDir             = "/var/run/secrets/tokens"
	jwtFile            = "jwt"
	summonBinDir       = "/conjur/bin"
	summonCfgDir       = "/conjur/summon"
	summonCfgFile      = "secrets.yml"
)

var injectorVolumes = []string{volPodInfo, volSecrets, volJWT, volSummonBin, volSummonCfg}

// Config is the cluster-wide Conjur connection info. App teams never see it.
type Config struct {
	ApplianceURL       string
	Account            string
	AuthnURL           string
	AuthenticatorID    string
	SSLCertificate     string
	ProviderImage      string
	ProviderPullPolicy string
	SummonImage        string
	SummonPullPolicy   string
	ProviderRunAsUser  int64 // 0 = unset; the provider image's USER is a name, so runAsNonRoot needs a numeric UID
	JWTAudience        string
	JWTExpiration      int64
	IdentityPath       string // Conjur policy branch holding the hosts, e.g. data/kubernetes/applications
}

type Result struct {
	Patch    []PatchOp
	Warnings []string
	Skipped  string // non-empty = no mutation, with the reason
}

// podCtx is everything the type-specific builders need.
type podCtx struct {
	cfg      Config
	pod      Pod
	ann      map[string]string
	targets  []int // indexes into pod.Spec.Containers
	identity string
	warnings []string
}

// Mutate decides whether to inject and returns the JSON patch.
// It never denies a pod: a broken annotation set gets a warning and no injection.
func Mutate(cfg Config, namespace string, raw []byte) (Result, error) {
	var pod Pod
	if err := json.Unmarshal(raw, &pod); err != nil {
		return Result{}, fmt.Errorf("decode pod: %w", err)
	}
	ann := pod.Metadata.Annotations
	if !strings.EqualFold(ann[annInject], "true") {
		return Result{Skipped: "not opted in"}, nil
	}
	if ann[annStatus] == "injected" ||
		hasContainer(pod.Spec.Containers, providerName) ||
		hasContainer(pod.Spec.InitContainers, providerName) ||
		hasContainer(pod.Spec.InitContainers, summonInitName) {
		return Result{Skipped: "already injected"}, nil
	}

	typ := strings.ToLower(ann[annInjectType])
	if typ == "" {
		typ = typeProvider
	}
	if typ != typeProvider && typ != typeSummon {
		return skipWarn("unsupported %s=%q (use secrets-provider or summon)", annInjectType, typ), nil
	}
	for _, v := range pod.Spec.Volumes {
		for _, n := range injectorVolumes {
			if v.Name == n {
				return skipWarn("pod already has a volume named %q", v.Name), nil
			}
		}
	}

	targets, err := resolveTargets(pod.Spec.Containers, ann[annInjectContainers])
	if err != nil {
		return skipWarn("%v", err), nil
	}

	sa := pod.Spec.ServiceAccountName
	if sa == "" {
		sa = "default"
	}
	if namespace == "" {
		namespace = pod.Metadata.Namespace
	}
	ctx := &podCtx{
		cfg:      cfg,
		pod:      pod,
		ann:      ann,
		targets:  targets,
		identity: fmt.Sprintf("host/%s/system:serviceaccount:%s:%s", strings.Trim(cfg.IdentityPath, "/"), namespace, sa),
	}

	if typ == typeSummon {
		return ctx.summon()
	}
	return ctx.provider()
}

// ---------------------------------------------------------------- provider

// provider injects the Secrets Provider. Placement and destination come from the
// provider's own annotations; the injector only fills in defaults.
func (c *podCtx) provider() (Result, error) {
	dest := strings.ToLower(c.ann[annDestination])
	if dest == "" {
		dest = "file"
	}
	switch dest {
	case "file":
		if !hasSecretsAnnotation(c.ann) {
			return skipWarn("secrets-destination=file needs at least one conjur.org/conjur-secrets.<group> annotation"), nil
		}
	case "k8s_secrets":
		if strings.TrimSpace(c.ann[annK8sSecrets]) == "" {
			return skipWarn("secrets-destination=k8s_secrets needs the %s annotation (list of target Secret names)", annK8sSecrets), nil
		}
	default:
		return skipWarn("unsupported %s=%q (use file or k8s_secrets)", annDestination, dest), nil
	}

	// Same defaults as the official examples: file -> sidecar, k8s_secrets -> init
	mode := strings.ToLower(c.ann[annContainerMode])
	if mode == "" {
		mode = "sidecar"
		if dest == "k8s_secrets" {
			mode = "init"
		}
	}
	if mode != "sidecar" && mode != "init" {
		return skipWarn("unsupported %s=%q (use sidecar or init)", annContainerMode, mode), nil
	}

	// Write back only what was defaulted, so the provider sees the same values the injector used.
	newAnn := map[string]string{annStatus: "injected", annIdentity: c.identity}
	if _, ok := c.ann[annDestination]; !ok {
		newAnn[annDestination] = dest
	}
	if _, ok := c.ann[annContainerMode]; !ok {
		newAnn[annContainerMode] = mode
	}
	if mode == "init" && strings.EqualFold(c.ann[annRefreshEnabled], "true") {
		c.warn("secrets refresh needs sidecar mode; forcing %s=false for init mode", annRefreshEnabled)
		newAnn[annRefreshEnabled] = "false"
	}

	ops := annotationOps(c.ann, newAnn)

	vols := []any{podInfoVolume(), jwtVolume(c.cfg)}
	if dest == "file" {
		vols = append(vols, map[string]any{"name": volSecrets, "emptyDir": map[string]any{"medium": "Memory"}})
	}
	ops = appendList(ops, "/spec/volumes", c.pod.Spec.Volumes == nil, vols)

	// push-to-file: app containers read the files from the shared in-memory volume.
	if dest == "file" {
		mountPath := c.ann[annInjectMountPath]
		if mountPath == "" {
			mountPath = providerSecretsDir
		}
		for _, i := range c.targets {
			vm := VolumeMount{Name: volSecrets, MountPath: mountPath, ReadOnly: true}
			ops = appendList(ops, fmt.Sprintf("/spec/containers/%d/volumeMounts", i), c.pod.Spec.Containers[i].VolumeMounts == nil, []any{vm})
		}
	} else if c.ann[annInjectContainers] != "" {
		c.warn("%s is ignored for k8s_secrets: apps consume the Secret via secretKeyRef/envFrom", annInjectContainers)
	}

	p := c.providerContainer(dest == "file")
	if mode == "init" {
		ops = appendList(ops, "/spec/initContainers", c.pod.Spec.InitContainers == nil, []any{p})
	} else {
		ops = append(ops, PatchOp{Op: "add", Path: "/spec/containers/-", Value: p})
	}
	return Result{Patch: ops, Warnings: c.warnings}, nil
}

func (c *podCtx) providerContainer(withSecretsVolume bool) Container {
	env := []EnvVar{
		{Name: "MY_POD_NAME", ValueFrom: &EnvVarSource{FieldRef: &FieldRef{FieldPath: "metadata.name"}}},
		{Name: "MY_POD_NAMESPACE", ValueFrom: &EnvVarSource{FieldRef: &FieldRef{FieldPath: "metadata.namespace"}}},
		{Name: "CONJUR_APPLIANCE_URL", Value: c.cfg.ApplianceURL},
		{Name: "CONJUR_ACCOUNT", Value: c.cfg.Account},
		{Name: "CONJUR_AUTHN_URL", Value: c.cfg.AuthnURL},
		{Name: "JWT_TOKEN_PATH", Value: jwtDir + "/" + jwtFile},
	}
	if c.cfg.AuthenticatorID != "" {
		env = append(env, EnvVar{Name: "CONJUR_AUTHENTICATOR_ID", Value: c.cfg.AuthenticatorID})
	}
	if c.cfg.SSLCertificate != "" {
		env = append(env, EnvVar{Name: "CONJUR_SSL_CERTIFICATE", Value: c.cfg.SSLCertificate})
	}
	mounts := []VolumeMount{
		{Name: volPodInfo, MountPath: "/conjur/podinfo", ReadOnly: true},
		{Name: volJWT, MountPath: jwtDir, ReadOnly: true},
	}
	if withSecretsVolume {
		mounts = append(mounts, VolumeMount{Name: volSecrets, MountPath: providerSecretsDir})
	}
	return Container{
		Name:            providerName,
		Image:           c.cfg.ProviderImage,
		ImagePullPolicy: c.cfg.ProviderPullPolicy,
		Env:             env,
		VolumeMounts:    mounts,
		Resources: &Resources{
			Requests: map[string]string{"cpu": "10m", "memory": "16Mi"},
			Limits:   map[string]string{"memory": "64Mi"},
		},
		SecurityContext: restrictedSecurityContext(c.cfg.ProviderRunAsUser),
	}
}

// ------------------------------------------------------------------ summon

// summon copies summon + summon-conjur into the pod with an init container and
// wraps the app's command, so secrets arrive as env vars - no image or CI change.
func (c *podCtx) summon() (Result, error) {
	if strings.TrimSpace(c.ann[annSummonSecrets]) == "" {
		return skipWarn("inject-type=summon needs the %s annotation (secrets.yml content)", annSummonSecrets), nil
	}
	if c.ann[annContainerMode] != "" || c.ann[annDestination] != "" {
		c.warn("%s/%s are ignored for summon: summon wraps the app process and delivers env vars", annContainerMode, annDestination)
	}

	// Resolve the original command of every target container before patching anything.
	commands := map[int][]string{}
	for _, i := range c.targets {
		ct := c.pod.Spec.Containers[i]
		switch {
		case len(ct.Command) > 0:
			commands[i] = ct.Command
		case c.ann[annSummonCommand] != "":
			cmd, err := parseCommand(c.ann[annSummonCommand])
			if err != nil {
				return skipWarn("cannot parse %s: %v", annSummonCommand, err), nil
			}
			commands[i] = cmd
		default:
			return skipWarn("container %q has no command in the manifest and no %s annotation - the injector cannot see the image ENTRYPOINT", ct.Name, annSummonCommand), nil
		}
	}

	ops := annotationOps(c.ann, map[string]string{annStatus: "injected", annIdentity: c.identity})

	vols := []any{
		map[string]any{"name": volSummonBin, "emptyDir": map[string]any{"medium": "Memory"}},
		// secrets.yml comes straight from the pod's own annotation - no ConfigMap needed
		map[string]any{"name": volSummonCfg, "downwardAPI": map[string]any{
			"items": []any{map[string]any{
				"path":     summonCfgFile,
				"fieldRef": map[string]any{"fieldPath": fmt.Sprintf("metadata.annotations['%s']", annSummonSecrets)},
			}},
		}},
		jwtVolume(c.cfg),
	}
	ops = appendList(ops, "/spec/volumes", c.pod.Spec.Volumes == nil, vols)

	initC := Container{
		Name:            summonInitName,
		Image:           c.cfg.SummonImage,
		ImagePullPolicy: c.cfg.SummonPullPolicy,
		Command:         []string{"cp", "/summon/summon", "/summon/summon-conjur", summonBinDir + "/"},
		VolumeMounts:    []VolumeMount{{Name: volSummonBin, MountPath: summonBinDir}},
		Resources: &Resources{
			Requests: map[string]string{"cpu": "10m", "memory": "8Mi"},
			Limits:   map[string]string{"memory": "32Mi"},
		},
		SecurityContext: restrictedSecurityContext(0), // image USER is numeric (65532)
	}
	ops = appendList(ops, "/spec/initContainers", c.pod.Spec.InitContainers == nil, []any{initC})

	summonEnv := c.summonEnv()
	for _, i := range c.targets {
		ct := c.pod.Spec.Containers[i]
		base := fmt.Sprintf("/spec/containers/%d", i)

		mounts := []any{
			VolumeMount{Name: volSummonBin, MountPath: summonBinDir, ReadOnly: true},
			VolumeMount{Name: volSummonCfg, MountPath: summonCfgDir, ReadOnly: true},
			VolumeMount{Name: volJWT, MountPath: jwtDir, ReadOnly: true},
		}
		ops = appendList(ops, base+"/volumeMounts", ct.VolumeMounts == nil, mounts)

		var env []any
		for _, e := range summonEnv {
			if hasEnv(ct.Env, e.Name) {
				c.warn("container %q already sets %s; keeping the app's value", ct.Name, e.Name)
				continue
			}
			env = append(env, e)
		}
		if len(env) > 0 {
			ops = appendList(ops, base+"/env", ct.Env == nil, env)
		}

		// args (if any) stay as they are - Kubernetes appends them after command.
		wrapped := append([]string{
			summonBinDir + "/summon",
			"--provider", summonBinDir + "/summon-conjur",
			"-f", summonCfgDir + "/" + summonCfgFile,
		}, commands[i]...)
		op := "add"
		if len(ct.Command) > 0 {
			op = "replace"
		}
		ops = append(ops, PatchOp{Op: op, Path: base + "/command", Value: wrapped})
	}
	return Result{Patch: ops, Warnings: c.warnings}, nil
}

// summonEnv is what summon-conjur needs to authenticate with authn-jwt.
func (c *podCtx) summonEnv() []EnvVar {
	env := []EnvVar{
		{Name: "CONJUR_APPLIANCE_URL", Value: c.cfg.ApplianceURL},
		{Name: "CONJUR_ACCOUNT", Value: c.cfg.Account},
		{Name: "CONJUR_AUTHN_JWT_SERVICE_ID", Value: c.cfg.AuthenticatorID},
		{Name: "JWT_TOKEN_PATH", Value: jwtDir + "/" + jwtFile},
	}
	if c.cfg.SSLCertificate != "" {
		env = append(env, EnvVar{Name: "CONJUR_SSL_CERTIFICATE", Value: c.cfg.SSLCertificate})
	}
	return env
}

// ----------------------------------------------------------------- helpers

// restrictedSecurityContext satisfies the Pod Security "restricted" profile, so injected
// containers are admitted in any namespace (restricted passes baseline and privileged too).
// runAsUser is only set when uid > 0: OpenShift assigns its own UID and rejects a fixed one.
func restrictedSecurityContext(uid int64) *SecurityContext {
	f, t := false, true
	sc := &SecurityContext{
		AllowPrivilegeEscalation: &f,
		RunAsNonRoot:             &t,
		Capabilities:             &Capabilities{Drop: []string{"ALL"}},
		SeccompProfile:           &SeccompProfile{Type: "RuntimeDefault"},
	}
	if uid > 0 {
		sc.RunAsUser = &uid
	}
	return sc
}

func (c *podCtx) warn(format string, a ...any) {
	c.warnings = append(c.warnings, "conjur-injector: "+fmt.Sprintf(format, a...))
}

func skipWarn(format string, a ...any) Result {
	msg := "conjur-injector: " + fmt.Sprintf(format, a...) + "; pod admitted without injection"
	return Result{Skipped: msg, Warnings: []string{msg}}
}

func resolveTargets(cs []Container, list string) ([]int, error) {
	var out []int
	if list == "" {
		for i := range cs {
			out = append(out, i)
		}
		return out, nil
	}
	want := map[string]bool{}
	for _, n := range strings.Split(list, ",") {
		if n = strings.TrimSpace(n); n != "" {
			want[n] = true
		}
	}
	for i, ct := range cs {
		if want[ct.Name] {
			out = append(out, i)
			delete(want, ct.Name)
		}
	}
	if len(want) > 0 {
		return nil, fmt.Errorf("%s lists unknown container(s) %s", annInjectContainers, keys(want))
	}
	return out, nil
}

// parseCommand accepts a JSON array (["dumb-init","--","/app"]) or a plain space-separated string.
func parseCommand(s string) ([]string, error) {
	s = strings.TrimSpace(s)
	if strings.HasPrefix(s, "[") {
		var cmd []string
		if err := json.Unmarshal([]byte(s), &cmd); err != nil {
			return nil, err
		}
		if len(cmd) == 0 {
			return nil, fmt.Errorf("empty command")
		}
		return cmd, nil
	}
	cmd := strings.Fields(s)
	if len(cmd) == 0 {
		return nil, fmt.Errorf("empty command")
	}
	return cmd, nil
}

func annotationOps(existing, newAnn map[string]string) []PatchOp {
	if existing == nil {
		return []PatchOp{{Op: "add", Path: "/metadata/annotations", Value: newAnn}}
	}
	var ops []PatchOp
	for _, k := range sortedKeys(newAnn) {
		op := "add"
		if _, ok := existing[k]; ok {
			op = "replace"
		}
		ops = append(ops, PatchOp{Op: op, Path: "/metadata/annotations/" + escape(k), Value: newAnn[k]})
	}
	return ops
}

func podInfoVolume() map[string]any {
	return map[string]any{"name": volPodInfo, "downwardAPI": map[string]any{
		"items": []any{map[string]any{"path": "annotations", "fieldRef": map[string]any{"fieldPath": "metadata.annotations"}}},
	}}
}

func jwtVolume(cfg Config) map[string]any {
	ts := map[string]any{"path": jwtFile}
	if cfg.JWTAudience != "" {
		ts["audience"] = cfg.JWTAudience
	}
	if cfg.JWTExpiration > 0 {
		ts["expirationSeconds"] = cfg.JWTExpiration
	}
	return map[string]any{"name": volJWT, "projected": map[string]any{"sources": []any{
		map[string]any{"serviceAccountToken": ts},
	}}}
}

// appendList adds items to a list at path, creating the list if it does not exist yet.
func appendList(ops []PatchOp, path string, missing bool, items []any) []PatchOp {
	if missing {
		return append(ops, PatchOp{Op: "add", Path: path, Value: items})
	}
	for _, it := range items {
		ops = append(ops, PatchOp{Op: "add", Path: path + "/-", Value: it})
	}
	return ops
}

func hasSecretsAnnotation(ann map[string]string) bool {
	for k := range ann {
		if strings.HasPrefix(k, annSecretsPrefix) && !strings.HasPrefix(k, annSecretsPrefix2) {
			return true
		}
	}
	return false
}

func hasContainer(cs []Container, name string) bool {
	for _, c := range cs {
		if c.Name == name {
			return true
		}
	}
	return false
}

func hasEnv(env []EnvVar, name string) bool {
	for _, e := range env {
		if e.Name == name {
			return true
		}
	}
	return false
}

// escape implements RFC 6901 JSON Pointer escaping (annotation keys contain '/').
func escape(s string) string {
	return strings.ReplaceAll(strings.ReplaceAll(s, "~", "~0"), "/", "~1")
}

func sortedKeys(m map[string]string) []string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}

func keys(m map[string]bool) string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	sort.Strings(out)
	return strings.Join(out, ",")
}
