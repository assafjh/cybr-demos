#!/bin/bash

# Set namespace
NAMESPACE="argocd"

# Enable SA Token
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: argocd-repo-server-token
  namespace: argocd
  annotations:
    kubernetes.io/service-account.name: argocd-repo-server
type: kubernetes.io/service-account-token
EOF

# ArgoCD Custom Plugin configuration
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: cmp-plugin
  namespace: argocd
data:
  avp.yaml: |-
    apiVersion: argoproj.io/v1alpha1
    kind: ConfigManagementPlugin
    metadata:
      name: argocd-vault-plugin
    spec:
      allowConcurrency: true
      discover:
        find:
          command:
            - sh
            - "-c"
            - "find . -name '*.yaml' | xargs -I {} grep \"<path\" {} | grep ."
      generate:
        command:
          - argocd-vault-plugin
          - generate
          - "./"
      lockRepo: false
EOF

# ArgoCD vault plugin and Conjur authenticator configuration
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: vault-plugin-cm
  namespace: argocd
data:
  AVP_AUTH_TYPE: authToken
  AVP_CONJUR_ACCOUNT: conjur
  AVP_CONJUR_SSL_CERT: |-
    $CONJUR_PUB_CERT
  AVP_CONJUR_TOKEN_FILE: /run/conjur/access-token
  AVP_CONJUR_URL: https://<tenant>.secretsmgr.cyberark.cloud/api
  AVP_TYPE: conjurvault
  # Addition for Conjur Authenticator
  CONJUR_AUTHN_URL: "https://<tenant>.secretsmgr.cyberark.cloud/api/authn-jwt/k8s-argocd1"
  CONJUR_AUTHENTICATOR_ID: "k8s-argocd1"
EOF

# Create the JSON patch file for the argocd-repo-server deployment
PATCH=$(cat <<EOF
[
 {
    "op": "add",
    "path": "/spec/template/spec/serviceAccountName",
    "value": "argocd-repo-server"
  },
  {
    "op": "add",
    "path": "/spec/template/spec/automountServiceAccountToken",
    "value": true
  },
{
    "op": "add",
    "path": "/spec/template/spec/containers/-",
    "value": {
      "name": "argocd-vault-plugin",
      "image": "itdistrict/argocd-vault-plugin:latest",
      "imagePullPolicy": "Always",
      "command": [
        "/var/run/argocd/argocd-cmp-server"
      ],
      "volumeMounts": [
        {
          "mountPath": "/var/run/argocd",
          "name": "var-files"
        },
        {
          "mountPath": "/home/argocd/cmp-server/plugins",
          "name": "plugins"
        },
        {
          "mountPath": "/tmp",
          "name": "tmp"
        },
        {
          "mountPath": "/home/argocd/cmp-server/config/plugin.yaml",
          "name": "cmp-plugin",
          "subPath": "avp.yaml"
        },
        {
          "mountPath": "/run/conjur",
          "name": "conjur-access-token"
        }
      ],
      "envFrom": [
        {
          "configMapRef": {
            "name": "vault-plugin-cm"
          }
        }
      ]
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/-",
    "value": {
      "name": "cyberark-conjur-authn",
      "image": "cyberark/conjur-authn-k8s-client:latest",
      "env": [
        {
          "name": "CONJUR_ACCOUNT",
          "valueFrom": {
            "configMapKeyRef": {
              "name": "vault-plugin-cm",
              "key": "AVP_CONJUR_ACCOUNT"
            }
          }
        },
        {
          "name": "CONJUR_SSL_CERTIFICATE",
          "valueFrom": {
            "configMapKeyRef": {
              "name": "vault-plugin-cm",
              "key": "AVP_CONJUR_SSL_CERT"
            }
          }
        },
        {
          "name": "CONJUR_APPLIANCE_URL",
          "valueFrom": {
            "configMapKeyRef": {
              "name": "vault-plugin-cm",
              "key": "AVP_CONJUR_URL"
            }
          }
        },
        {
          "name": "CONJUR_AUTHENTICATOR_ID",
          "valueFrom": {
            "configMapKeyRef": {
              "name": "vault-plugin-cm",
              "key": "CONJUR_AUTHENTICATOR_ID"
            }
          }
        },
        {
          "name": "CONJUR_AUTHN_URL",
          "valueFrom": {
            "configMapKeyRef": {
              "name": "vault-plugin-cm",
              "key": "CONJUR_AUTHN_URL"
            }
          }
        },
        {
          "name": "MY_POD_NAME",
          "valueFrom": {
            "fieldRef": {
              "apiVersion": "v1",
              "fieldPath": "metadata.name"
            }
          }
        },
        {
          "name": "MY_POD_NAMESPACE",
          "valueFrom": {
            "fieldRef": {
              "apiVersion": "v1",
              "fieldPath": "metadata.namespace"
            }
          }
        }
      ],
      "volumeMounts": [
        {
          "mountPath": "/run/conjur",
          "name": "conjur-access-token"
        },
        {
          "mountPath": "/var/run/secrets/kubernetes.io/serviceaccount",
          "name": "kube-api-access"
        }
      ]
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "argocd-vault-plugin",
      "emptyDir": {}
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "conjur-access-token",
      "emptyDir": {}
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "kube-api-access",
      "projected": {
        "sources": [
          {
            "serviceAccountToken": {
              "path": "token"
            }
          }
        ]
      }
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "cmp-plugin",
      "configMap": {
        "name": "cmp-plugin"
      }
    }
  }
]
EOF
)

# Apply the JSON patch to the argocd-repo-server deployment
kubectl patch deployment argocd-repo-server -n $NAMESPACE --type='json' -p "$PATCH"

# Wait for the argocd-repo-server deployment to be ready
kubectl rollout status deployment argocd-repo-server -n $NAMESPACE
