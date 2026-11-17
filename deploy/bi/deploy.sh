#!/bin/bash
# Build on this machine, copy the image onto the BI node, then start it.
# The node does not pull from Harbor or Docker Hub.
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
export KUBECONFIG="${KUBECONFIG:-/Users/zhujinqi/Documents/env/pem/config}"

namespace="${NAMESPACE:-datart}"
node="${NODE:-centos}"
stamp="$(date -u +%Y%m%d%H%M%S)"
image="datart/wren-sidecar:${stamp}"
python_image="${PYTHON_IMAGE:-172.30.10.185:15000/common/python:3.13-slim}"
repo="$(cd "${root}/../.." && pwd)"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is not installed" >&2
  exit 1
fi
if ! command -v docker >/dev/null 2>&1; then
  echo "docker is not installed" >&2
  exit 1
fi

load_image_on_node() {
  local tar="$1"
  echo "把镜像拷到节点 ${node} 并导入"
  kubectl -n "${namespace}" delete pod image-loader --ignore-not-found --wait=true >/dev/null
  kubectl -n "${namespace}" apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: image-loader
  namespace: ${namespace}
spec:
  restartPolicy: Never
  nodeName: ${node}
  containers:
    - name: loader
      image: ${python_image}
      imagePullPolicy: IfNotPresent
      command: ["sleep", "3600"]
      securityContext:
        privileged: true
      volumeMounts:
        - name: images
          mountPath: /images
        - name: host
          mountPath: /host
  volumes:
    - name: images
      hostPath:
        path: /tmp/wren-sidecar-images
        type: DirectoryOrCreate
    - name: host
      hostPath:
        path: /
EOF
  kubectl -n "${namespace}" wait --for=condition=Ready pod/image-loader --timeout=180s
  kubectl -n "${namespace}" cp "${tar}" image-loader:/images/wren-sidecar.tar
  kubectl -n "${namespace}" exec image-loader -- \
    chroot /host sh -c 'if [ -S /run/k3s/containerd/containerd.sock ]; then
      ctr --address /run/k3s/containerd/containerd.sock -n k8s.io images import /tmp/wren-sidecar-images/wren-sidecar.tar
    else
      ctr -n k8s.io images import /tmp/wren-sidecar-images/wren-sidecar.tar
    fi'
  kubectl -n "${namespace}" exec image-loader -- \
    chroot /host sh -c "ctr -n k8s.io images ls -q | while read -r name; do
      case \"\${name}\" in
        *datart/wren-sidecar:${stamp}) ;;
        *datart/wren-sidecar:*) ctr -n k8s.io images rm \"\${name}\" || true ;;
      esac
    done"
  kubectl -n "${namespace}" exec image-loader -- \
    chroot /host rm -f /tmp/wren-sidecar-images/wren-sidecar.tar
  kubectl -n "${namespace}" delete pod image-loader --wait=true >/dev/null
}

echo "kubeconfig: ${KUBECONFIG}"
echo "namespace:  ${namespace}"
echo "node:       ${node}"
echo "image:      ${image}"

if [ "${SKIP_BUILD:-}" != "1" ]; then
  "${repo}/docker/wren-sidecar/build.sh"
  docker build --platform linux/amd64 \
    -f "${repo}/docker/wren-sidecar/Dockerfile" \
    -t "${image}" "${repo}"
  image_tar="${root}/wren-sidecar.tar"
  echo "导出镜像"
  docker save -o "${image_tar}" "${image}"
  ls -lh "${image_tar}"
  load_image_on_node "${image_tar}"
  rm -f "${image_tar}"
fi

published_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
sed \
  -e "s#IMAGE#${image}#g" \
  -e "s#NODE_NAME#${node}#g" \
  -e "s#PUBLISHED_AT#${published_at}#g" \
  "${root}/wren-sidecar.yaml" | kubectl apply -f -
kubectl -n "${namespace}" rollout status deployment/wren-sidecar --timeout=180s || true
kubectl -n "${namespace}" get pods -l app=wren-sidecar -o wide
kubectl -n "${namespace}" get svc wren-sidecar
