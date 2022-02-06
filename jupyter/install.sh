helm upgrade --cleanup-on-fail \
  --install jupyterhub jupyterhub/jupyterhub \
  --namespace default \
  --values config.yaml

kubectl --namespace=default get svc proxy-public
