package main

import (
	"encoding/json"
	"strconv"
	"strings"
	"testing"
)

var testCfg = Config{
	ApplianceURL:       "https://conjur.example.com",
	Account:            "conjur",
	AuthnURL:           "https://conjur.example.com/authn-jwt/k8s-cluster1",
	AuthenticatorID:    "k8s-cluster1",
	SSLCertificate:     "-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----",
	ProviderImage:      "cyberark/secrets-provider-for-k8s:latest",
	ProviderPullPolicy: "IfNotPresent",
	SummonImage:        "ghcr.io/assafjh/conjur-summon-bin:latest",
	SummonPullPolicy:   "IfNotPresent",
	JWTExpiration:      3600,
	ProviderRunAsUser:  777,
	IdentityPath:       "data/kubernetes/applications",
}

// ---------- fixtures ----------

const filePod = `{
  "metadata": {"generateName": "demo-", "annotations": {
    "conjur.org/inject": "true",
    "conjur.org/inject-mount-path": "/opt/secrets/conjur",
    "conjur.org/conjur-secrets-policy-path.app": "data/kubernetes/applications/safe/",
    "conjur.org/conjur-secrets.app": "- secret1: secret1\n",
    "conjur.org/secret-file-path.app": "./credentials.yaml"
  }},
  "spec": {"serviceAccountName": "webhook-demo-app",
    "containers": [{"name": "app", "image": "busybox"}, {"name": "metrics", "image": "busybox", "volumeMounts": [{"name": "x", "mountPath": "/x"}]}],
    "volumes": [{"name": "x", "emptyDir": {}}]}
}`

const k8sPod = `{
  "metadata": {"annotations": {
    "conjur.org/inject": "true",
    "conjur.org/secrets-destination": "k8s_secrets",
    "conjur.org/k8s-secrets": "- webhook-demo-credentials\n"
  }},
  "spec": {"serviceAccountName": "webhook-demo-app",
    "containers": [{"name": "app", "image": "busybox",
      "env": [{"name": "SECRET4", "valueFrom": {"secretKeyRef": {"name": "webhook-demo-credentials", "key": "secret4"}}}]}]}
}`

const summonPod = `{
  "metadata": {"annotations": {
    "conjur.org/inject": "true",
    "conjur.org/inject-type": "summon",
    "conjur.org/summon-secrets": "SECRET2: !var data/kubernetes/applications/safe/secret2\n"
  }},
  "spec": {"serviceAccountName": "webhook-demo-app",
    "containers": [{"name": "app", "image": "alpine", "command": ["/app/run"], "args": ["--port", "8080"],
      "env": [{"name": "CONJUR_ACCOUNT", "value": "mine"}]}]}
}`

// ---------- helpers ----------

func mutated(t *testing.T, pod, ns string) (map[string]any, Result) {
	t.Helper()
	res, err := Mutate(testCfg, ns, []byte(pod))
	if err != nil {
		t.Fatal(err)
	}
	var doc any
	json.Unmarshal([]byte(pod), &doc)
	b, _ := json.Marshal(res.Patch) // round-trip so values are plain JSON types
	var ops []PatchOp
	json.Unmarshal(b, &ops)
	for _, op := range ops {
		doc = apply(t, doc, op)
	}
	return doc.(map[string]any), res
}

func annOf(pod map[string]any) map[string]any {
	return pod["metadata"].(map[string]any)["annotations"].(map[string]any)
}
func specOf(pod map[string]any) map[string]any { return pod["spec"].(map[string]any) }
func list(m map[string]any, k string) []any {
	if v, ok := m[k].([]any); ok {
		return v
	}
	return nil
}
func names(items []any) []string {
	var out []string
	for _, it := range items {
		out = append(out, it.(map[string]any)["name"].(string))
	}
	return out
}
func envVal(c map[string]any, name string) (string, bool) {
	for _, e := range list(c, "env") {
		em := e.(map[string]any)
		if em["name"] == name {
			v, _ := em["value"].(string)
			return v, true
		}
	}
	return "", false
}
func with(pod, after, insert string) string { return strings.Replace(pod, after, after+insert, 1) }

// ---------- file ----------

func TestFileSidecar(t *testing.T) {
	pod, res := mutated(t, filePod, "conjur-webhook-demo")
	if res.Skipped != "" {
		t.Fatalf("unexpected skip: %s", res.Skipped)
	}
	ann := annOf(pod)
	if ann[annContainerMode] != "sidecar" || ann[annDestination] != "file" || ann[annStatus] != "injected" {
		t.Errorf("annotations: %v", ann)
	}
	if ann[annIdentity] != "host/data/kubernetes/applications/system:serviceaccount:conjur-webhook-demo:webhook-demo-app" {
		t.Errorf("identity = %v", ann[annIdentity])
	}
	cs := list(specOf(pod), "containers")
	if got := names(cs); strings.Join(got, ",") != "app,metrics,"+providerName {
		t.Fatalf("containers: %v", got)
	}
	for _, i := range []int{0, 1} {
		vms := list(cs[i].(map[string]any), "volumeMounts")
		last := vms[len(vms)-1].(map[string]any)
		if last["name"] != volSecrets || last["mountPath"] != "/opt/secrets/conjur" || last["readOnly"] != true {
			t.Errorf("container %d mounts: %v", i, vms)
		}
	}
	if got := names(list(specOf(pod), "volumes")); strings.Join(got, ",") != "x,"+volPodInfo+","+volJWT+","+volSecrets {
		t.Errorf("volumes: %v", got)
	}
	if v, _ := envVal(cs[2].(map[string]any), "JWT_TOKEN_PATH"); v != "/var/run/secrets/tokens/jwt" {
		t.Error("JWT_TOKEN_PATH not set on provider")
	}
	assertRestricted(t, cs[2].(map[string]any), `"runAsUser":777,`)
}

func assertRestricted(t *testing.T, c map[string]any, uid string) {
	t.Helper()
	sc, _ := json.Marshal(c["securityContext"])
	want := `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsNonRoot":true,` + uid + `"seccompProfile":{"type":"RuntimeDefault"}}`
	if string(sc) != want {
		t.Errorf("%v securityContext = %s", c["name"], sc)
	}
}

func TestFileInitAndContainerFilter(t *testing.T) {
	p := with(filePod, `"conjur.org/inject": "true",`,
		` "conjur.org/container-mode": "init", "conjur.org/inject-containers": "app", "conjur.org/secrets-refresh-enabled": "true",`)
	pod, res := mutated(t, p, "ns1")
	spec := specOf(pod)
	if len(list(spec, "containers")) != 2 {
		t.Error("init mode must not add a regular container")
	}
	if got := names(list(spec, "initContainers")); len(got) != 1 || got[0] != providerName {
		t.Errorf("initContainers: %v", got)
	}
	metrics := list(spec, "containers")[1].(map[string]any)
	if len(list(metrics, "volumeMounts")) != 1 {
		t.Error("metrics not in inject-containers, must not get the mount")
	}
	ann := annOf(pod)
	if ann[annRefreshEnabled] != "false" || ann[annContainerMode] != "init" || len(res.Warnings) != 1 {
		t.Errorf("refresh/mode handling: %v warnings=%v", ann, res.Warnings)
	}
}

func TestExplicitProviderAnnotationsAreKept(t *testing.T) {
	p := with(filePod, `"conjur.org/inject": "true",`, ` "conjur.org/container-mode": "sidecar", "conjur.org/secrets-destination": "file",`)
	res, _ := Mutate(testCfg, "ns", []byte(p))
	for _, op := range res.Patch {
		if strings.Contains(op.Path, "container-mode") || strings.Contains(op.Path, "secrets-destination") {
			t.Errorf("injector must not rewrite annotations the app set: %+v", op)
		}
	}
	if len(res.Warnings) != 0 {
		t.Errorf("no warnings expected: %v", res.Warnings)
	}
}

// ---------- k8s-secrets ----------

func TestK8sSecretsDefaultsToInit(t *testing.T) {
	pod, res := mutated(t, k8sPod, "ns")
	if res.Skipped != "" {
		t.Fatalf("unexpected skip: %s", res.Skipped)
	}
	ann := annOf(pod)
	if ann[annDestination] != "k8s_secrets" || ann[annContainerMode] != "init" {
		t.Errorf("annotations: %v", ann)
	}
	spec := specOf(pod)
	ic := list(spec, "initContainers")
	if got := names(ic); len(got) != 1 || got[0] != providerName {
		t.Fatalf("initContainers: %v", got)
	}
	for _, m := range list(ic[0].(map[string]any), "volumeMounts") {
		if m.(map[string]any)["name"] == volSecrets {
			t.Error("k8s-secrets provider must not mount the file volume")
		}
	}
	if got := names(list(spec, "volumes")); strings.Join(got, ",") != volPodInfo+","+volJWT {
		t.Errorf("volumes: %v", got)
	}
	app := list(spec, "containers")[0].(map[string]any)
	if len(list(app, "volumeMounts")) != 0 {
		t.Error("app container must not get mounts in k8s-secrets mode")
	}
}

func TestK8sSecretsSidecar(t *testing.T) {
	p := with(k8sPod, `"conjur.org/secrets-destination": "k8s_secrets",`, ` "conjur.org/container-mode": "sidecar",`)
	pod, _ := mutated(t, p, "ns")
	if got := names(list(specOf(pod), "containers")); strings.Join(got, ",") != "app,"+providerName {
		t.Errorf("containers: %v", got)
	}
}

// ---------- summon ----------

func TestSummonWrapsManifestCommand(t *testing.T) {
	pod, res := mutated(t, summonPod, "ns")
	if res.Skipped != "" {
		t.Fatalf("unexpected skip: %s", res.Skipped)
	}
	spec := specOf(pod)
	if got := names(list(spec, "initContainers")); len(got) != 1 || got[0] != summonInitName {
		t.Fatalf("initContainers: %v", got)
	}
	if got := names(list(spec, "containers")); len(got) != 1 {
		t.Errorf("summon must not add a regular container: %v", got)
	}
	assertRestricted(t, list(spec, "initContainers")[0].(map[string]any), "")
	if _, ok := list(spec, "containers")[0].(map[string]any)["securityContext"]; ok {
		t.Error("the app container's securityContext must be left alone")
	}
	app := list(spec, "containers")[0].(map[string]any)
	cmd, _ := json.Marshal(app["command"])
	want := `["/conjur/bin/summon","--provider","/conjur/bin/summon-conjur","-f","/conjur/summon/secrets.yml","/app/run"]`
	if string(cmd) != want {
		t.Errorf("command = %s", cmd)
	}
	if args, _ := json.Marshal(app["args"]); string(args) != `["--port","8080"]` {
		t.Errorf("args must be untouched: %s", args)
	}
	if v, _ := envVal(app, "CONJUR_ACCOUNT"); v != "mine" {
		t.Error("app's own env must win")
	}
	if v, _ := envVal(app, "CONJUR_AUTHN_JWT_SERVICE_ID"); v != "k8s-cluster1" {
		t.Error("CONJUR_AUTHN_JWT_SERVICE_ID missing")
	}
	if len(res.Warnings) != 1 {
		t.Errorf("expected one env-conflict warning, got %v", res.Warnings)
	}
	vols := list(spec, "volumes")
	if got := names(vols); strings.Join(got, ",") != volSummonBin+","+volSummonCfg+","+volJWT {
		t.Errorf("volumes: %v", got)
	}
	cfgVol, _ := json.Marshal(vols[1])
	if !strings.Contains(string(cfgVol), `metadata.annotations['conjur.org/summon-secrets']`) {
		t.Errorf("secrets.yml must be projected from the annotation: %s", cfgVol)
	}
}

func TestSummonCommandFromAnnotation(t *testing.T) {
	p := strings.Replace(summonPod, `"command": ["/app/run"], "args": ["--port", "8080"],`, "", 1)
	p = with(p, `"conjur.org/inject-type": "summon",`, ` "conjur.org/summon-command": "[\"dumb-init\",\"--\",\"/scripts/entry-point.sh\"]",`)
	pod, res := mutated(t, p, "ns")
	if res.Skipped != "" {
		t.Fatalf("unexpected skip: %s", res.Skipped)
	}
	app := list(specOf(pod), "containers")[0].(map[string]any)
	cmd, _ := json.Marshal(app["command"])
	if !strings.HasSuffix(string(cmd), `"dumb-init","--","/scripts/entry-point.sh"]`) {
		t.Errorf("command = %s", cmd)
	}
	// plain string form
	got, _ := parseCommand("  /bin/app  --flag ")
	if strings.Join(got, "|") != "/bin/app|--flag" {
		t.Errorf("parseCommand = %v", got)
	}
}

// ---------- skips ----------

func TestSkips(t *testing.T) {
	noCmd := strings.Replace(summonPod, `"command": ["/app/run"], "args": ["--port", "8080"],`, "", 1)
	cases := map[string]string{
		"not opted in":     `{"metadata":{},"spec":{"containers":[{"name":"a"}]}}`,
		"file no secrets":  strings.Replace(filePod, `"conjur.org/conjur-secrets.app": "- secret1: secret1\n",`, "", 1),
		"bad type":         with(filePod, `"conjur.org/inject": "true",`, ` "conjur.org/inject-type": "secretless",`),
		"bad mode":         with(filePod, `"conjur.org/inject": "true",`, ` "conjur.org/container-mode": "magic",`),
		"bad destination":  with(filePod, `"conjur.org/inject": "true",`, ` "conjur.org/secrets-destination": "vault",`),
		"unknown target":   with(filePod, `"conjur.org/inject": "true",`, ` "conjur.org/inject-containers": "nope",`),
		"volume clash":     strings.Replace(filePod, `{"name": "x", "emptyDir": {}}`, `{"name": "conjur-summon-bin", "emptyDir": {}}`, 1),
		"already injected": strings.Replace(filePod, `{"name": "app", "image": "busybox"}`, `{"name": "conjur-secrets-provider", "image": "busybox"}`, 1),
		"k8s no list":      strings.Replace(k8sPod, `"conjur.org/k8s-secrets": "- webhook-demo-credentials\n"`, `"conjur.org/k8s-secrets": ""`, 1),
		"summon no yml":    strings.Replace(summonPod, `"conjur.org/summon-secrets": "SECRET2: !var data/kubernetes/applications/safe/secret2\n"`, `"x": "y"`, 1),
		"summon no cmd":    noCmd,
		"summon bad cmd":   with(noCmd, `"conjur.org/inject-type": "summon",`, ` "conjur.org/summon-command": "[broken",`),
	}
	for name, p := range cases {
		res, err := Mutate(testCfg, "ns", []byte(p))
		if err != nil || res.Skipped == "" || len(res.Patch) != 0 {
			t.Errorf("%s: expected skip, got %+v err=%v", name, res, err)
		}
	}
}

func TestEscape(t *testing.T) {
	if got := escape("conjur.org/inject-status"); got != "conjur.org~1inject-status" {
		t.Errorf("escape = %s", got)
	}
}

// ---------- minimal JSON Patch applier (add / replace) for tests only ----------

func apply(t *testing.T, doc any, op PatchOp) any {
	t.Helper()
	parts := strings.Split(strings.TrimPrefix(op.Path, "/"), "/")
	for i := range parts {
		parts[i] = strings.ReplaceAll(strings.ReplaceAll(parts[i], "~1", "/"), "~0", "~")
	}
	return setPath(t, doc, parts, op)
}

func setPath(t *testing.T, node any, parts []string, op PatchOp) any {
	key := parts[0]
	last := len(parts) == 1
	switch n := node.(type) {
	case map[string]any:
		if last {
			_, exists := n[key]
			if op.Op == "replace" && !exists {
				t.Fatalf("replace of missing %s", op.Path)
			}
			if op.Op == "add" && exists {
				if _, isList := n[key].([]any); isList {
					t.Fatalf("add would overwrite existing list %s", op.Path)
				}
			}
			n[key] = op.Value
			return n
		}
		child, ok := n[key]
		if !ok {
			t.Fatalf("missing path segment %q in %s", key, op.Path)
		}
		n[key] = setPath(t, child, parts[1:], op)
		return n
	case []any:
		if last && key == "-" {
			return append(n, op.Value)
		}
		i, err := strconv.Atoi(key)
		if err != nil || i >= len(n) {
			t.Fatalf("bad index %q in %s", key, op.Path)
		}
		if last {
			n[i] = op.Value
			return n
		}
		n[i] = setPath(t, n[i], parts[1:], op)
		return n
	}
	t.Fatalf("cannot traverse %s", op.Path)
	return nil
}
