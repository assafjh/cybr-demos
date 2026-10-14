package main

import "encoding/json"

// Minimal Kubernetes types — only the fields the injector reads or writes.
// Kept dependency-free on purpose (no client-go), so the image is a single static binary.

type AdmissionReview struct {
	APIVersion string             `json:"apiVersion"`
	Kind       string             `json:"kind"`
	Request    *AdmissionRequest  `json:"request,omitempty"`
	Response   *AdmissionResponse `json:"response,omitempty"`
}

type GroupVersionKind struct {
	Group   string `json:"group"`
	Version string `json:"version"`
	Kind    string `json:"kind"`
}

type AdmissionRequest struct {
	UID       string           `json:"uid"`
	Kind      GroupVersionKind `json:"kind"`
	Namespace string           `json:"namespace,omitempty"`
	Operation string           `json:"operation"`
	DryRun    *bool            `json:"dryRun,omitempty"`
	Object    json.RawMessage  `json:"object,omitempty"`
}

type Status struct {
	Message string `json:"message,omitempty"`
	Code    int32  `json:"code,omitempty"`
}

type AdmissionResponse struct {
	UID       string   `json:"uid"`
	Allowed   bool     `json:"allowed"`
	PatchType *string  `json:"patchType,omitempty"`
	Patch     []byte   `json:"patch,omitempty"` // base64-encoded by encoding/json, as the API expects
	Warnings  []string `json:"warnings,omitempty"`
	Result    *Status  `json:"result,omitempty"`
}

type Pod struct {
	Metadata ObjectMeta `json:"metadata"`
	Spec     PodSpec    `json:"spec"`
}

type ObjectMeta struct {
	Name         string            `json:"name,omitempty"`
	GenerateName string            `json:"generateName,omitempty"`
	Namespace    string            `json:"namespace,omitempty"`
	Annotations  map[string]string `json:"annotations,omitempty"`
}

type PodSpec struct {
	ServiceAccountName string      `json:"serviceAccountName,omitempty"`
	Containers         []Container `json:"containers"`
	InitContainers     []Container `json:"initContainers,omitempty"`
	Volumes            []NamedItem `json:"volumes,omitempty"`
}

type NamedItem struct {
	Name string `json:"name"`
}

type Container struct {
	Name            string           `json:"name"`
	Image           string           `json:"image,omitempty"`
	ImagePullPolicy string           `json:"imagePullPolicy,omitempty"`
	Command         []string         `json:"command,omitempty"`
	Args            []string         `json:"args,omitempty"`
	Env             []EnvVar         `json:"env,omitempty"`
	VolumeMounts    []VolumeMount    `json:"volumeMounts,omitempty"`
	Resources       *Resources       `json:"resources,omitempty"`
	SecurityContext *SecurityContext `json:"securityContext,omitempty"`
}

type EnvVar struct {
	Name      string        `json:"name"`
	Value     string        `json:"value,omitempty"`
	ValueFrom *EnvVarSource `json:"valueFrom,omitempty"`
}

type EnvVarSource struct {
	FieldRef *FieldRef `json:"fieldRef,omitempty"`
}

type FieldRef struct {
	FieldPath string `json:"fieldPath"`
}

type VolumeMount struct {
	Name      string `json:"name"`
	MountPath string `json:"mountPath"`
	ReadOnly  bool   `json:"readOnly,omitempty"`
}

type Resources struct {
	Requests map[string]string `json:"requests,omitempty"`
	Limits   map[string]string `json:"limits,omitempty"`
}

type SecurityContext struct {
	AllowPrivilegeEscalation *bool           `json:"allowPrivilegeEscalation,omitempty"`
	ReadOnlyRootFilesystem   *bool           `json:"readOnlyRootFilesystem,omitempty"`
	RunAsNonRoot             *bool           `json:"runAsNonRoot,omitempty"`
	RunAsUser                *int64          `json:"runAsUser,omitempty"`
	Capabilities             *Capabilities   `json:"capabilities,omitempty"`
	SeccompProfile           *SeccompProfile `json:"seccompProfile,omitempty"`
}

type Capabilities struct {
	Drop []string `json:"drop,omitempty"`
}

type SeccompProfile struct {
	Type string `json:"type"`
}

// PatchOp is a single RFC 6902 JSON Patch operation.
type PatchOp struct {
	Op    string `json:"op"`
	Path  string `json:"path"`
	Value any    `json:"value,omitempty"`
}
