
```shell
kubectl create secret tls ydphoto-com-tls \
  --cert=fullchain.pem \
  --key=privkey.pem \
  -n kube-system
```