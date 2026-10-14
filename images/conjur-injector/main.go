package main

import (
	"crypto/tls"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
	"path"
	"strconv"
	"strings"
	"time"
)

func env(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

func loadConfig() Config {
	exp, _ := strconv.ParseInt(env("JWT_EXPIRATION_SECONDS", "3600"), 10, 64)
	// The Secrets Provider image runs as USER secrets-provider (uid 777). Kubelet cannot verify
	// runAsNonRoot for a named user, so pin the uid. Set to 0 on OpenShift (it assigns the uid).
	uid, _ := strconv.ParseInt(env("PROVIDER_RUN_AS_USER", "777"), 10, 64)
	cfg := Config{
		ApplianceURL:       os.Getenv("CONJUR_APPLIANCE_URL"),
		Account:            env("CONJUR_ACCOUNT", "conjur"),
		AuthnURL:           os.Getenv("CONJUR_AUTHN_URL"),
		AuthenticatorID:    os.Getenv("CONJUR_AUTHENTICATOR_ID"),
		SSLCertificate:     os.Getenv("CONJUR_SSL_CERTIFICATE"),
		ProviderImage:      env("PROVIDER_IMAGE", "cyberark/secrets-provider-for-k8s:latest"),
		ProviderPullPolicy: env("PROVIDER_IMAGE_PULL_POLICY", "IfNotPresent"),
		SummonImage:        env("SUMMON_IMAGE", "ghcr.io/assafjh/conjur-summon-bin:latest"),
		SummonPullPolicy:   env("SUMMON_IMAGE_PULL_POLICY", "IfNotPresent"),
		JWTAudience:        os.Getenv("JWT_AUDIENCE"),
		JWTExpiration:      exp,
		ProviderRunAsUser:  uid,
		IdentityPath:       env("CONJUR_IDENTITY_PATH", "data/kubernetes/applications"),
	}
	if cfg.ApplianceURL == "" || cfg.AuthnURL == "" {
		log.Fatal("CONJUR_APPLIANCE_URL and CONJUR_AUTHN_URL are required")
	}
	// summon-conjur needs the service id; derive it from .../authn-jwt/<id> if not set
	if cfg.AuthenticatorID == "" {
		cfg.AuthenticatorID = path.Base(strings.TrimRight(cfg.AuthnURL, "/"))
	}
	return cfg
}

func main() {
	cfg := loadConfig()
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) { w.Write([]byte("ok")) })
	mux.HandleFunc("/mutate", func(w http.ResponseWriter, r *http.Request) { handleMutate(cfg, w, r) })

	// The deploy script restarts the injector after rotating the certificate, so it is read once.
	certFile := env("TLS_CERT_FILE", "/etc/webhook/certs/tls.crt")
	keyFile := env("TLS_KEY_FILE", "/etc/webhook/certs/tls.key")
	srv := &http.Server{
		Addr:              env("LISTEN_ADDR", ":8443"),
		Handler:           mux,
		ReadHeaderTimeout: 10 * time.Second,
		TLSConfig:         &tls.Config{MinVersion: tls.VersionTLS12},
	}
	log.Printf("conjur-injector listening on %s (provider %s, summon %s, identity path %s)", srv.Addr, cfg.ProviderImage, cfg.SummonImage, cfg.IdentityPath)
	log.Fatal(srv.ListenAndServeTLS(certFile, keyFile))
}

func handleMutate(cfg Config, w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(io.LimitReader(r.Body, 3<<20))
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	var review AdmissionReview
	if err := json.Unmarshal(body, &review); err != nil || review.Request == nil {
		http.Error(w, "invalid AdmissionReview", http.StatusBadRequest)
		return
	}
	req := review.Request
	resp := &AdmissionResponse{UID: req.UID, Allowed: true}

	if req.Kind.Kind == "Pod" && req.Operation == "CREATE" {
		res, err := Mutate(cfg, req.Namespace, req.Object)
		switch {
		case err != nil:
			// Never block a pod on our own bug — admit it and say why.
			log.Printf("uid=%s ns=%s error: %v", req.UID, req.Namespace, err)
			resp.Warnings = []string{"conjur-injector: " + err.Error()}
		case res.Skipped != "":
			if len(res.Warnings) > 0 {
				log.Printf("uid=%s ns=%s skipped: %s", req.UID, req.Namespace, res.Skipped)
			}
			resp.Warnings = res.Warnings
		default:
			patch, _ := json.Marshal(res.Patch)
			pt := "JSONPatch"
			resp.Patch, resp.PatchType = patch, &pt
			resp.Warnings = res.Warnings
			log.Printf("uid=%s ns=%s injected (%d patch ops)", req.UID, req.Namespace, len(res.Patch))
		}
	}

	out, _ := json.Marshal(AdmissionReview{APIVersion: "admission.k8s.io/v1", Kind: "AdmissionReview", Response: resp})
	w.Header().Set("Content-Type", "application/json")
	w.Write(out)
}
